import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/role.dart';
import './auth_service.dart'; // Para obtener usuario actual
import './role_service.dart'; // Para obtener roles

class PermissionService {
  final AuthService _authService = AuthService();
  final RoleService _roleService = RoleService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache simple para no leer el rol repetidamente en la misma sesión/build
  Role? _currentUserRole;
  String? _cachedUserId;

  Future<bool> hasPermission(String permissionKey) async {
    final User? user = _authService.currentUser;
    if (user == null) {
      print("DEBUG_PERM: Permiso DENEGADO ($permissionKey) - Usuario no autenticado.");
      return false; 
    }
    print("DEBUG_PERM: Verificando permiso '$permissionKey' para usuario ${user.uid}...");

    // 1. Comprobar si es SuperAdmin
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && (userDoc.data()?['isSuperUser'] == true)) {
        print("DEBUG_PERM: CONCEDIDO ($permissionKey) - Usuario ${user.uid} es SuperAdmin.");
        return true; 
      }
      print("DEBUG_PERM: Usuario ${user.uid} NO es SuperAdmin.");
    } catch (e) {
      print("DEBUG_PERM: ⚠️ Error al verificar flag SuperAdmin para ${user.uid}: $e");
    }
    
    // 2. Obtener y cachear el rol del usuario
    // Comprobar si necesitamos recargar el rol (usuario diferente o primera vez)
    bool needsRoleReload = _currentUserRole == null || _cachedUserId != user.uid;
    print("DEBUG_PERM: ¿Necesita recargar rol? $needsRoleReload (Cache ID: $_cachedUserId, User ID: ${user.uid})");

    if (needsRoleReload) {
       _cachedUserId = user.uid; 
       _currentUserRole = null; 
       print("DEBUG_PERM: Intentando obtener roleId para ${user.uid}...");
       try {
         final userDoc = await _firestore.collection('users').doc(user.uid).get();
         final roleId = userDoc.data()?['roleId'] as String?; 
         print("DEBUG_PERM: roleId obtenido para ${user.uid}: '$roleId'");
         
         if (roleId != null && roleId.isNotEmpty) {
            print("DEBUG_PERM: Buscando rol con ID: $roleId...");
            _currentUserRole = await _roleService.getRoleById(roleId);
            if (_currentUserRole == null) {
               print("DEBUG_PERM: ⚠️ Rol con ID $roleId NO encontrado.");
            } else {
               print("DEBUG_PERM: ✅ Rol '${_currentUserRole!.name}' (ID: ${_currentUserRole!.id}) encontrado y cacheado.");
               print("DEBUG_PERM: Permisos del rol: ${_currentUserRole!.permissions}");
            }
         } else {
            print("DEBUG_PERM: Usuario ${user.uid} no tiene roleId válido asignado.");
         }

      } catch (e) {
        print("DEBUG_PERM: ❌ Error al obtener documento de usuario o rol para ${user.uid}: $e");
        _currentUserRole = null; 
      }
    } else {
       print("DEBUG_PERM: Usando rol cacheado '${_currentUserRole?.name ?? 'ninguno'}'. Permisos: ${_currentUserRole?.permissions}");
    }

    // 3. Verificar permiso en el rol cacheado
    if (_currentUserRole != null && _currentUserRole!.permissions.contains(permissionKey)) {
      print("DEBUG_PERM: CONCEDIDO ($permissionKey) - Permiso encontrado en rol '${_currentUserRole!.name}'.");
      return true;
    }

    print("DEBUG_PERM: DENEGADO ($permissionKey) - Permiso no encontrado para rol '${_currentUserRole?.name ?? 'ninguno'}'.");
    return false; 
  }

  // Método para limpiar caché si el rol del usuario cambia
  void clearRoleCache() {
    _currentUserRole = null;
    _cachedUserId = null;
    print("ℹ️ Caché de rol limpiada.");
  }
  
  // Método de diagnóstico para obtener todos los permisos de un usuario
  Future<Map<String, bool>> getAllPermissions() async {
    final Map<String, bool> result = {};
    final User? user = _authService.currentUser;
    
    if (user == null) {
      print("DEBUG_DIAGNÓSTICO: No hay usuario autenticado");
      return result;
    }
    
    // Lista de todos los permisos conocidos en el sistema
    final permissionsList = [
      'manage_roles',
      'assign_user_roles',
      'view_user_list',
      'view_user_details',
      'manage_pages',
      'manage_donations_config',
      'manage_livestream_config',
      'manage_announcements',
      'manage_home_sections',
      'manage_profile_fields',
      'send_push_notifications',
      'manage_cults',
      'create_ministry',
      'create_group',
      'manage_counseling_availability',
      'manage_counseling_requests',
      'manage_private_prayers',
      'manage_event_attendance',
      'view_ministry_stats',
      'view_group_stats',
      'view_schedule_stats',
      'manage_videos'
    ];
    
    // Comprobar si es SuperUser primero
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final bool isSuperUser = userDoc.data()?['isSuperUser'] == true;
      
      // Si es SuperUser, tiene todos los permisos
      if (isSuperUser) {
        for (final permission in permissionsList) {
          result[permission] = true;
        }
        print("DEBUG_DIAGNÓSTICO: Usuario es SuperUser, todos los permisos concedidos");
        return result;
      }
      
      // Si no es SuperUser, verificar cada permiso
      for (final permission in permissionsList) {
        result[permission] = await hasPermission(permission);
      }
      
    } catch (e) {
      print("DEBUG_DIAGNÓSTICO: Error al verificar permisos: $e");
    }
    
    return result;
  }

  // Método para verificar si el usuario tiene al menos uno de los permisos especificados
  Future<bool> hasAnyPermission(List<String> permissionKeys) async {
    final User? user = _authService.currentUser;
    if (user == null) {
      print("DEBUG_PERM: Permisos DENEGADOS ${permissionKeys.join(', ')} - Usuario no autenticado.");
      return false; 
    }
    print("DEBUG_PERM: Verificando permisos '${permissionKeys.join(', ')}' para usuario ${user.uid}...");

    // 1. Comprobar si es SuperAdmin
    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists && (userDoc.data()?['isSuperUser'] == true)) {
        print("DEBUG_PERM: CONCEDIDO (${permissionKeys.join(', ')}) - Usuario ${user.uid} es SuperAdmin.");
        return true; 
      }
      print("DEBUG_PERM: Usuario ${user.uid} NO es SuperAdmin.");
    } catch (e) {
      print("DEBUG_PERM: ⚠️ Error al verificar flag SuperAdmin para ${user.uid}: $e");
    }
    
    // 2. Obtener y cachear el rol del usuario si aún no está cacheado
    bool needsRoleReload = _currentUserRole == null || _cachedUserId != user.uid;
    print("DEBUG_PERM: ¿Necesita recargar rol? $needsRoleReload (Cache ID: $_cachedUserId, User ID: ${user.uid})");

    if (needsRoleReload) {
       _cachedUserId = user.uid; 
       _currentUserRole = null; 
       print("DEBUG_PERM: Intentando obtener roleId para ${user.uid}...");
       try {
         final userDoc = await _firestore.collection('users').doc(user.uid).get();
         final roleId = userDoc.data()?['roleId'] as String?; 
         print("DEBUG_PERM: roleId obtenido para ${user.uid}: '$roleId'");
         
         if (roleId != null && roleId.isNotEmpty) {
            print("DEBUG_PERM: Buscando rol con ID: $roleId...");
            _currentUserRole = await _roleService.getRoleById(roleId);
            if (_currentUserRole == null) {
               print("DEBUG_PERM: ⚠️ Rol con ID $roleId NO encontrado.");
            } else {
               print("DEBUG_PERM: ✅ Rol '${_currentUserRole!.name}' (ID: ${_currentUserRole!.id}) encontrado y cacheado.");
               print("DEBUG_PERM: Permisos del rol: ${_currentUserRole!.permissions}");
            }
         } else {
            print("DEBUG_PERM: Usuario ${user.uid} no tiene roleId válido asignado.");
         }
      } catch (e) {
        print("DEBUG_PERM: ❌ Error al obtener documento de usuario o rol para ${user.uid}: $e");
        _currentUserRole = null; 
      }
    } else {
       print("DEBUG_PERM: Usando rol cacheado '${_currentUserRole?.name ?? 'ninguno'}'. Permisos: ${_currentUserRole?.permissions}");
    }

    // 3. Verificar si el usuario tiene alguno de los permisos especificados
    if (_currentUserRole != null) {
      for (final permissionKey in permissionKeys) {
        if (_currentUserRole!.permissions.contains(permissionKey)) {
          print("DEBUG_PERM: CONCEDIDO ($permissionKey) - Permiso encontrado en rol '${_currentUserRole!.name}'.");
          return true;
        }
      }
    }

    print("DEBUG_PERM: DENEGADO (${permissionKeys.join(', ')}) - Ningún permiso encontrado para rol '${_currentUserRole?.name ?? 'ninguno'}'.");
    return false; 
  }
} 