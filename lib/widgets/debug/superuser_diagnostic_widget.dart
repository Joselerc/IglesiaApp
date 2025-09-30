import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/permission_service.dart';

/// Widget de diagnóstico para verificar el estado de SuperUser
/// 
/// Este widget proporciona una herramienta de depuración para verificar:
/// - Si el usuario está correctamente autenticado
/// - Si el documento del usuario existe en Firestore
/// - El valor exacto del campo 'isSuperUser' en la base de datos
/// - El estado actual de los permisos administrativos
/// - Pruebas de permisos específicos
/// 
/// Útil para diagnosticar problemas cuando un usuario con isSuperUser = true
/// no puede ver las opciones de administración en el perfil.
/// 
/// Uso: SuperUserDiagnosticWidget.showDiagnostic(context)
class SuperUserDiagnosticWidget {
  static final PermissionService _permissionService = PermissionService();

  /// Muestra el diálogo de diagnóstico de SuperUser
  /// 
  /// [context] - BuildContext necesario para mostrar el diálogo
  /// [hasAdminAccess] - Estado actual de _hasAdminAccess del ProfileScreen
  static Future<void> showDiagnostic(BuildContext context, {bool? hasAdminAccess}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showDiagnosticDialog(context, "❌ Error", "No hay usuario autenticado");
        return;
      }

      // 1. Verificar datos del usuario en Firestore
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      
      String diagnosticInfo = "🔍 DIAGNÓSTICO SUPERUSER\n\n";
      diagnosticInfo += "👤 Usuario ID: ${user.uid}\n";
      diagnosticInfo += "📧 Email: ${user.email}\n\n";
      
      if (!userDoc.exists) {
        diagnosticInfo += "❌ El documento del usuario NO existe en Firestore\n";
      } else {
        final userData = userDoc.data() as Map<String, dynamic>;
        diagnosticInfo += "✅ Documento del usuario existe\n\n";
        
        // Verificar isSuperUser
        final isSuperUser = userData['isSuperUser'];
        diagnosticInfo += "🔑 isSuperUser: $isSuperUser (${isSuperUser.runtimeType})\n";
        diagnosticInfo += "🔑 isSuperUser == true: ${isSuperUser == true}\n\n";
        
        // Verificar roleId
        final roleId = userData['roleId'];
        diagnosticInfo += "👥 roleId: $roleId\n\n";
        
        // Verificar hasAdminAccess si se proporcionó
        if (hasAdminAccess != null) {
          diagnosticInfo += "🛡️ _hasAdminAccess: $hasAdminAccess\n\n";
        }
        
        // Probar algunos permisos específicos
        diagnosticInfo += "📋 PRUEBA DE PERMISOS:\n";
        final testPermissions = [
          'manage_donations_config', 
          'view_user_list', 
          'manage_roles', 
          'create_ministry',
          'manage_announcements',
          'send_push_notifications'
        ];
        
        for (final perm in testPermissions) {
          final hasPermission = await _permissionService.hasPermission(perm);
          diagnosticInfo += "• $perm: ${hasPermission ? '✅' : '❌'}\n";
        }
        
        // Agregar recomendaciones si hay problemas
        if (isSuperUser != true) {
          diagnosticInfo += "\n💡 SOLUCIÓN:\n";
          diagnosticInfo += "Para convertir este usuario en SuperUser:\n";
          diagnosticInfo += "1. Ve a Firebase Console → Firestore\n";
          diagnosticInfo += "2. Colección 'users' → Documento '${user.uid}'\n";
          diagnosticInfo += "3. Agrega/edita: isSuperUser: true (boolean)\n";
        }
      }
      
      _showDiagnosticDialog(context, "🔍 Diagnóstico SuperUser", diagnosticInfo);
      
    } catch (e) {
      _showDiagnosticDialog(context, "❌ Error", "Error en diagnóstico: $e");
    }
  }

  /// Muestra el diálogo con la información de diagnóstico
  static void _showDiagnosticDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: const TextStyle(
                fontFamily: 'monospace', 
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Botón de diagnóstico reutilizable
  /// 
  /// Crea un botón que puede ser insertado en cualquier pantalla
  /// para acceder al diagnóstico de SuperUser
  static Widget buildDiagnosticButton({bool? hasAdminAccess}) {
    return Builder(
      builder: (context) => TextButton.icon(
        icon: const Icon(Icons.bug_report, size: 16),
        label: const Text("🔍 Diagnóstico SuperUser", style: TextStyle(fontSize: 14)),
        onPressed: () => showDiagnostic(context, hasAdminAccess: hasAdminAccess),
        style: TextButton.styleFrom(
          foregroundColor: Colors.orange,
        ),
      ),
    );
  }
}
