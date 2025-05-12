import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class GuestUtils {
  static final AuthService _authService = AuthService();
  
  /// Verifica si el usuario actual es invitado y muestra un diálogo si lo es
  /// Devuelve true si el usuario es invitado, false si no lo es
  static Future<bool> checkGuestAndShowDialog(BuildContext context) async {
    final bool isGuest = await _authService.isCurrentUserGuest();
    
    if (isGuest) {
      // Si es invitado, mostrar diálogo
      if (context.mounted) {
        await showGuestRestrictedDialog(context);
      }
    }
    
    return isGuest;
  }
  
  /// Muestra un diálogo informando que la función está restringida para usuarios registrados
  static Future<void> showGuestRestrictedDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.lock_outline, color: AppColors.secondary),
              const SizedBox(width: 8),
              Text(
                'Função restrita',
                style: AppTextStyles.subtitle1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            'Esta função está disponível apenas para usuários registrados.',
            style: AppTextStyles.bodyText2,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
              },
              child: Text(
                'Voltar',
                style: TextStyle(color: AppColors.mutedGray),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pushNamed('/register'); // Ir a pantalla de registro
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Criar conta'),
            ),
          ],
        );
      },
    );
  }
} 