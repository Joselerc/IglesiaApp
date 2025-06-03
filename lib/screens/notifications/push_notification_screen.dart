import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';
import '../../services/simple_notification_service.dart';
import '../../services/permission_service.dart';
import '../../services/cloud_functions_service.dart';
import '../../models/ministry.dart';
import '../../models/group.dart';
import '../../models/notification.dart';
import '../../theme/app_colors.dart';
import 'package:provider/provider.dart';

class PushNotificationScreen extends StatefulWidget {
  const PushNotificationScreen({Key? key}) : super(key: key);

  @override
  State<PushNotificationScreen> createState() => _PushNotificationScreenState();
}

class _PushNotificationScreenState extends State<PushNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final NotificationService _notificationService = NotificationService();
  final SimpleNotificationService _simpleNotificationService = SimpleNotificationService();
  final CloudFunctionsService _cloudFunctionsService = CloudFunctionsService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  
  // Filtros
  String _targetType = 'all'; // all, ministry, group
  String? _selectedMinistryId;
  String? _selectedGroupId;
  bool _includeSelf = true; // Opción para que el pastor reciba sus propias notificaciones

  // Selección múltiple de usuarios
  final Map<String, bool> _selectedMinistryMembers = {};
  final Map<String, bool> _selectedGroupMembers = {};
  
  // Listas para dropdowns
  List<Ministry> _ministries = [];
  List<Map<String, dynamic>> _groups = [];
  
  // Miembros disponibles
  List<Map<String, dynamic>> _ministryMembers = [];
  List<Map<String, dynamic>> _groupMembers = [];
  
  @override
  void initState() {
    super.initState();
    _loadMinistries();
    _loadGroups();
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }
  
  Future<void> _loadMinistries() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('ministries').get();
      setState(() {
        _ministries = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return Ministry(
                id: doc.id,
                name: data['name'] ?? '',
                description: data['description'] ?? '',
                imageUrl: data['imageUrl'] ?? '',
                adminIds: data['adminIds'] != null 
                    ? List<String>.from(data['adminIds']) 
                    : [],
                memberIds: data['memberIds'] != null 
                    ? List<String>.from(data['memberIds']) 
                    : [],
                pendingRequests: data['pendingRequests'] ?? {},
                rejectedRequests: data['rejectedRequests'] ?? {},
                createdAt: data['createdAt'] != null 
                    ? (data['createdAt'] as Timestamp).toDate() 
                    : DateTime.now(),
                updatedAt: data['updatedAt'] != null
                    ? (data['updatedAt'] as Timestamp).toDate()
                    : DateTime.now(),
              );
            })
            .toList();
      });
    } catch (e) {
      print('Error al cargar ministerios: $e');
    }
  }
  
  Future<void> _loadGroups() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('groups').get();
      setState(() {
        _groups = snapshot.docs
            .map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'] ?? 'Grupo sin nombre',
              };
            })
            .toList();
      });
    } catch (e) {
      print('Error al cargar grupos: $e');
    }
  }

  Future<void> _loadMinistryMembers(String ministryId) async {
    try {
      setState(() => _isLoading = true);
      final ministryDoc = await FirebaseFirestore.instance
          .collection('ministries')
          .doc(ministryId)
          .get();
      
      if (ministryDoc.exists) {
        final ministryData = ministryDoc.data() as Map<String, dynamic>;
        List<String> memberIds = [];
        
        if (ministryData['memberIds'] != null) {
          memberIds = List<String>.from(ministryData['memberIds']);
        } else if (ministryData['members'] != null) {
          // Manejamos tanto memberIds como members, según como esté estructurado
          final members = ministryData['members'] as List;
          memberIds = members.map((member) {
            if (member is DocumentReference) {
              return member.id;
            } else if (member is String && member.startsWith('/users/')) {
              return member.substring(7); // Quitar '/users/'
            }
            return member.toString();
          }).toList();
        }
        
        // Cargamos la información de cada miembro
        _ministryMembers = [];
        _selectedMinistryMembers.clear();
        
        for (final memberId in memberIds) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            _ministryMembers.add({
              'id': memberId,
              'name': userData['displayName'] ?? 'Usuario sin nombre',
              'photoUrl': userData['photoUrl'] ?? '',
            });
            
            // Por defecto, todos los miembros están seleccionados
            _selectedMinistryMembers[memberId] = true;
          }
        }
        
        setState(() {});
      }
      
    } catch (e) {
      print('Error al cargar miembros del ministerio: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGroupMembers(String groupId) async {
    try {
      setState(() => _isLoading = true);
      final groupDoc = await FirebaseFirestore.instance
          .collection('groups')
          .doc(groupId)
          .get();
      
      if (groupDoc.exists) {
        final groupData = groupDoc.data() as Map<String, dynamic>;
        List<String> memberIds = [];
        
        if (groupData['memberIds'] != null) {
          memberIds = List<String>.from(groupData['memberIds']);
        } else if (groupData['members'] != null) {
          // Similar al ministerio, manejamos diferentes estructuras
          final members = groupData['members'] as List;
          memberIds = members.map((member) {
            if (member is DocumentReference) {
              return member.id;
            } else if (member is String && member.startsWith('/users/')) {
              return member.substring(7); // Quitar '/users/'
            }
            return member.toString();
          }).toList();
        }
        
        // Cargamos la información de cada miembro
        _groupMembers = [];
        _selectedGroupMembers.clear();
        
        for (final memberId in memberIds) {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();
          
          if (userDoc.exists) {
            final userData = userDoc.data() as Map<String, dynamic>;
            _groupMembers.add({
              'id': memberId,
              'name': userData['displayName'] ?? 'Usuario sin nombre',
              'photoUrl': userData['photoUrl'] ?? '',
            });
            
            // Por defecto, todos los miembros están seleccionados
            _selectedGroupMembers[memberId] = true;
          }
        }
        
        setState(() {});
      }
      
    } catch (e) {
      print('Error al cargar miembros del grupo: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _showSuccessSnackbar(int recipientCount, {int failureCount = 0}) {
    if (!mounted) return;
    
    String message = 'Notificação enviada a $recipientCount usuários';
    if (failureCount > 0) {
      message += ' ($failureCount falharam)';
    }
    
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      backgroundColor: failureCount > 0 ? Colors.orange : Colors.green,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.fixed,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
    );
    
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
  
  Future<List<String>> _getTargetUsers() async {
    List<String> userIds = [];
    final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    print('🔍 Pastor ID (currentUserId): $currentUserId');
    
    switch (_targetType) {
      case 'all':
        // Obtener todos los usuarios
        final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
        userIds = usersSnapshot.docs.map((doc) => doc.id).toList();
        print('📋 Usuarios totales encontrados: ${userIds.length}');
        break;
        
      case 'ministry':
        if (_selectedMinistryId != null) {
          // Obtener solo los miembros seleccionados
          userIds = _selectedMinistryMembers.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
          print('📋 Miembros del ministerio seleccionados: ${userIds.length}');
        }
        break;
        
      case 'group':
        if (_selectedGroupId != null) {
          // Obtener solo los miembros seleccionados
          userIds = _selectedGroupMembers.entries
              .where((entry) => entry.value)
              .map((entry) => entry.key)
              .toList();
          print('📋 Miembros del grupo seleccionados: ${userIds.length}');
        }
        break;
    }
    
    // Si no se debe incluir al remitente (pastor), eliminarlo de la lista
    if (!_includeSelf && userIds.contains(currentUserId)) {
      userIds.remove(currentUserId);
      print('🚫 Pastor excluido de la lista de destinatarios');
    }
    
    // Si debe incluirse al remitente pero no está en la lista, añadirlo
    if (_includeSelf && !userIds.contains(currentUserId)) {
      userIds.add(currentUserId);
      print('✅ Pastor añadido a la lista de destinatarios');
    } else if (_includeSelf) {
      print('✅ Pastor ya está en la lista de destinatarios');
    }
    
    print('📋 Lista final de destinatarios: $userIds');
    print('✅ ¿Incluye al pastor?: ${userIds.contains(currentUserId)}');
    
    return userIds;
  }
  
  Future<void> _sendNotification() async {
    // --- Doble verificación de permiso --- 
    final bool hasPermission = await _permissionService.hasPermission('send_push_notifications');
    if (!hasPermission) {
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Você não tem permissão para enviar notificações.'), backgroundColor: Colors.red),
         );
      }
      return; // No continuar si no tiene permiso
    }
    // -------------------------------------

    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final title = _titleController.text.trim();
      final message = _messageController.text.trim();
      final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
      
      print('🔔 Enviando notificación: "$title" / "$message"');
      print('🔔 Pastor ID: $currentUserId');
      
      // Obtener lista de users IDs según el filtro seleccionado
      List<String> targetUserIds = await _getTargetUsers();
      
      if (targetUserIds.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No hay usuarios que cumplan con los criterios seleccionados'),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isLoading = false);
        return;
      }
      
      print('📤 Enviando notificación push via Cloud Function...');
      
      // Usar Cloud Function para enviar las notificaciones
      final result = await _cloudFunctionsService.sendPushNotifications(
        userIds: targetUserIds,
        title: title,
        body: message,
        customData: {
          'type': 'custom_push',
          'sender': currentUserId,
        },
      );
      
      print('✅ Cloud Function completada: ${result['successCount']} exitosas, ${result['failureCount']} fallidas');
      
      // También crear las notificaciones en Firestore para el historial
      // (Esto se puede hacer en paralelo con las push notifications)
      for (final userId in targetUserIds) {
        await _notificationService.createNotification(
          userId: userId,
          title: title,
          message: message,
          type: NotificationType.custom,
          senderId: currentUserId,
          data: {
            'type': 'custom_push',
            'sender': currentUserId,
          },
        );
      }
      
      if (mounted) {
        // Mostrar snackbar de éxito con el número de destinatarios
        _showSuccessSnackbar(
          result['successCount'] ?? targetUserIds.length,
          failureCount: result['failureCount'] ?? 0,
        );
        
        // Limpiar formulario
        _titleController.clear();
        _messageController.clear();
      }
    } catch (e) {
      print('❌ Error al enviar notificación: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Enviar Notificações Push'),
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
      ),
      body: FutureBuilder<bool>(
        future: _permissionService.hasPermission('send_push_notifications'),
        builder: (context, permissionSnapshot) {
          if (permissionSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (permissionSnapshot.hasError) {
            return Center(child: Text('Erro ao verificar permissão: ${permissionSnapshot.error}'));
          }
          
          if (!permissionSnapshot.hasData || permissionSnapshot.data == false) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                   mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                      Icon(
                        Icons.notifications_off,
                        size: 64,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Acesso não autorizado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Você não tem permissão para enviar notificações push.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                   ],
                 ),
              ),
            );
          }

          return _isLoading
              ? Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tarjeta de envío
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Enviar notificação',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Campo de título
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: TextFormField(
                                    controller: _titleController,
                                    decoration: const InputDecoration(
                                      labelText: 'Título',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.title),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor insira um título';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Campo de mensaje
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: TextFormField(
                                    controller: _messageController,
                                    decoration: const InputDecoration(
                                      labelText: 'Mensagem',
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                                      border: InputBorder.none,
                                      prefixIcon: Icon(Icons.message),
                                      alignLabelWithHint: true,
                                    ),
                                    maxLines: 5,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor insira uma mensagem';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Tarjeta de filtros
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Destinatários',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                
                                // Opciones de filtrado
                                Column(
                                  children: [
                                    // Todos los usuarios
                                    RadioListTile<String>(
                                      title: const Text('Todos os membros'),
                                      value: 'all',
                                      groupValue: _targetType,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) {
                                        setState(() {
                                          _targetType = value!;
                                        });
                                      },
                                    ),
                                    
                                    // Miembros de un ministerio
                                    RadioListTile<String>(
                                      title: const Text('Membros de um ministério'),
                                      value: 'ministry',
                                      groupValue: _targetType,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) {
                                        setState(() {
                                          _targetType = value!;
                                          // Limpiar selección anterior
                                          _selectedMinistryId = null;
                                          _ministryMembers = [];
                                          _selectedMinistryMembers.clear();
                                        });
                                      },
                                    ),
                                    
                                    // Selector de ministerio (visible solo si se selecciona la opción)
                                    if (_targetType == 'ministry') ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                              labelText: 'Selecionar ministério',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                              border: InputBorder.none,
                                            ),
                                            items: _ministries.map((ministry) {
                                              return DropdownMenuItem<String>(
                                                value: ministry.id,
                                                child: Text(ministry.name),
                                              );
                                            }).toList(),
                                            value: _selectedMinistryId,
                                            onChanged: (value) {
                                              if (value != _selectedMinistryId) {
                                                setState(() {
                                                  _selectedMinistryId = value;
                                                  _selectedMinistryMembers.clear();
                                                  _ministryMembers = [];
                                                });
                                                if (value != null) {
                                                  _loadMinistryMembers(value);
                                                }
                                              }
                                            },
                                            validator: _targetType == 'ministry'
                                                ? (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Por favor selecione um ministério';
                                                    }
                                                    return null;
                                                  }
                                                : null,
                                          ),
                                        ),
                                      ),
                                      
                                      // Lista de miembros del ministerio para selección múltiple
                                      if (_ministryMembers.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Selecionar membros (${_selectedMinistryMembers.values.where((selected) => selected).length}/${_ministryMembers.length})',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final bool allSelected = _selectedMinistryMembers.values.every((selected) => selected);
                                                      setState(() {
                                                        for (final member in _ministryMembers) {
                                                          _selectedMinistryMembers[member['id']] = !allSelected;
                                                        }
                                                      });
                                                    },
                                                    child: Text(
                                                      _selectedMinistryMembers.values.every((selected) => selected)
                                                          ? 'Desmarcar todos'
                                                          : 'Selecionar todos',
                                                      style: TextStyle(
                                                        color: AppColors.primary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey[300]!),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                height: 200,
                                                child: ListView.builder(
                                                  itemCount: _ministryMembers.length,
                                                  itemBuilder: (context, index) {
                                                    final member = _ministryMembers[index];
                                                    final memberId = member['id'];
                                                    
                                                    return CheckboxListTile(
                                                      title: Text(
                                                        member['name'],
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                      value: _selectedMinistryMembers[memberId] ?? false,
                                                      activeColor: AppColors.primary,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _selectedMinistryMembers[memberId] = value!;
                                                        });
                                                      },
                                                      dense: true,
                                                      controlAffinity: ListTileControlAffinity.leading,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                    
                                    // Miembros de un grupo
                                    RadioListTile<String>(
                                      title: const Text('Membros de um grupo'),
                                      value: 'group',
                                      groupValue: _targetType,
                                      activeColor: AppColors.primary,
                                      onChanged: (value) {
                                        setState(() {
                                          _targetType = value!;
                                          // Limpiar selección anterior
                                          _selectedGroupId = null;
                                          _groupMembers = [];
                                          _selectedGroupMembers.clear();
                                        });
                                      },
                                    ),
                                    
                                    // Selector de grupo (visible solo si se selecciona la opción)
                                    if (_targetType == 'group') ...[
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: Colors.grey[300]!),
                                          ),
                                          child: DropdownButtonFormField<String>(
                                            decoration: const InputDecoration(
                                              labelText: 'Selecionar grupo',
                                              contentPadding: EdgeInsets.symmetric(horizontal: 12),
                                              border: InputBorder.none,
                                            ),
                                            items: _groups.map((group) {
                                              return DropdownMenuItem<String>(
                                                value: group['id'],
                                                child: Text(group['name']),
                                              );
                                            }).toList(),
                                            value: _selectedGroupId,
                                            onChanged: (value) {
                                              if (value != _selectedGroupId) {
                                                setState(() {
                                                  _selectedGroupId = value;
                                                  _selectedGroupMembers.clear();
                                                  _groupMembers = [];
                                                });
                                                if (value != null) {
                                                  _loadGroupMembers(value);
                                                }
                                              }
                                            },
                                            validator: _targetType == 'group'
                                                ? (value) {
                                                    if (value == null || value.isEmpty) {
                                                      return 'Por favor selecione um grupo';
                                                    }
                                                    return null;
                                                  }
                                                : null,
                                          ),
                                        ),
                                      ),
                                      
                                      // Lista de miembros del grupo para selección múltiple
                                      if (_groupMembers.isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(
                                                    'Selecionar (${_selectedGroupMembers.values.where((selected) => selected).length}/${_groupMembers.length})',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                  TextButton(
                                                    onPressed: () {
                                                      final bool allSelected = _selectedGroupMembers.values.every((selected) => selected);
                                                      setState(() {
                                                        for (final member in _groupMembers) {
                                                          _selectedGroupMembers[member['id']] = !allSelected;
                                                        }
                                                      });
                                                    },
                                                    child: Text(
                                                      _selectedGroupMembers.values.every((selected) => selected)
                                                          ? 'Desmarcar todos'
                                                          : 'Selecionar todos',
                                                      style: TextStyle(
                                                        color: AppColors.primary,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 8),
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey[300]!),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                height: 200,
                                                child: ListView.builder(
                                                  itemCount: _groupMembers.length,
                                                  itemBuilder: (context, index) {
                                                    final member = _groupMembers[index];
                                                    final memberId = member['id'];
                                                    
                                                    return CheckboxListTile(
                                                      title: Text(
                                                        member['name'],
                                                        style: const TextStyle(fontSize: 14),
                                                      ),
                                                      value: _selectedGroupMembers[memberId] ?? false,
                                                      activeColor: AppColors.primary,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          _selectedGroupMembers[memberId] = value!;
                                                        });
                                                      },
                                                      dense: true,
                                                      controlAffinity: ListTileControlAffinity.leading,
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Opción para incluirse a sí mismo
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          color: Colors.white,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Receber também esta notificação',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                Switch(
                                  value: _includeSelf,
                                  activeColor: AppColors.primary,
                                  onChanged: (value) {
                                    setState(() {
                                      _includeSelf = value;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Botón de enviar
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _sendNotification,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'ENVIAR NOTIFICAÇÃO',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        
                        // Espacio para el padding inferior
                        SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
                      ],
                    ),
                  ),
                );
        },
      ),
    );
  }
} 