import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountDeletionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Muestra el diálogo inicial de confirmación de eliminación de cuenta
  static void showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 28),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Eliminar Conta',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta ação é irreversível e resultará em:',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _buildWarningItem('• Eliminação permanente de todos os seus dados'),
              _buildWarningItem('• Remoção de todos os grupos e ministérios'),
              _buildWarningItem('• Perda de todo o histórico de mensagens'),
              _buildWarningItem('• Eliminação completa do perfil'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: const Text(
                  '⚠️ Esta ação NÃO PODE ser desfeita. Tem certeza absoluta?',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showFinalDeleteConfirmation(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  /// Widget helper para items de advertencia
  static Widget _buildWarningItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(fontSize: 14, height: 1.3),
      ),
    );
  }

  /// Muestra la confirmación final con input de texto
  static void _showFinalDeleteConfirmation(BuildContext context) {
    final TextEditingController confirmController = TextEditingController();
    bool isConfirmationValid = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Confirmação Final',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Para confirmar a eliminação da sua conta, digite:',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'ELIMINAR MINHA CONTA',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: confirmController,
                    decoration: const InputDecoration(
                      labelText: 'Digite a frase exata acima',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.edit),
                    ),
                    onChanged: (value) {
                      setState(() {
                        isConfirmationValid = value == 'ELIMINAR MINHA CONTA';
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton(
                  onPressed: isConfirmationValid ? () => _executeAccountDeletion(context) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirmationValid ? Colors.red : Colors.grey,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('ELIMINAR CONTA'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Ejecuta el proceso completo de eliminación de cuenta
  static Future<void> _executeAccountDeletion(BuildContext context) async {
    // Cerrar el diálogo de confirmación
    Navigator.of(context).pop();
    
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Eliminando conta...'),
            ],
          ),
        );
      },
    );

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      final userId = user.uid;
      debugPrint('🗑️ Iniciando eliminação de conta para usuário: $userId');

      // Proceso de eliminación paso a paso
      await _deleteUserData(userId);
      await _removeUserFromCollections(userId);
      await _deleteRelatedUserData(userId);

      // Cerrar el diálogo de carga ANTES de eliminar la cuenta
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Finalmente, eliminar la cuenta de Firebase Auth
      debugPrint('🗑️ Eliminando conta do Firebase Auth...');
      await user.delete();

      debugPrint('✅ Conta eliminada com sucesso');

      // Esperar un momento para que Firebase procese la eliminación
      await Future.delayed(const Duration(milliseconds: 500));

      // Verificar si el contexto sigue montado y forzar navegación
      if (context.mounted) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta eliminada com sucesso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Esperar un poco más para que el usuario vea el mensaje
        await Future.delayed(const Duration(milliseconds: 1000));

        // Forzar navegación directa al login/auth wrapper
        if (context.mounted) {
          // Limpiar toda la pila de navegación y ir a auth
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/', // Ruta principal que debería ir al AuthWrapper
            (route) => false, // Eliminar todas las rutas anteriores
          );
        }
      }

    } catch (e) {
      debugPrint('❌ Erro ao eliminar conta: $e');
      
      // Cerrar el diálogo de carga si está abierto
      if (context.mounted) {
        // Intentar cerrar cualquier diálogo que pueda estar abierto
        Navigator.of(context).popUntil((route) => route.isFirst);
        
        // Mostrar error específico
        String errorMessage = 'Erro inesperado ao eliminar conta';
        
        if (e.toString().contains('requires-recent-login')) {
          errorMessage = 'Por segurança, faça login novamente antes de eliminar a conta';
        } else if (e.toString().contains('network')) {
          errorMessage = 'Erro de conexão. Verifique sua internet e tente novamente';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Tentar Novamente',
              textColor: Colors.white,
              onPressed: () => showDeleteAccountConfirmation(context),
            ),
          ),
        );
      }
    }
  }

  /// Elimina el documento principal del usuario y respuestas de perfil
  static Future<void> _deleteUserData(String userId) async {
    debugPrint('🗑️ Eliminando documento de usuario de Firestore...');
    
    // Eliminar documento principal del usuario
    await _firestore.collection('users').doc(userId).delete();

    // Eliminar respuestas de campos de perfil
    debugPrint('🗑️ Eliminando respostas de campos de perfil...');
    final profileResponses = await _firestore
        .collection('profile_field_responses')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (var doc in profileResponses.docs) {
      await doc.reference.delete();
    }
  }

  /// Remueve el usuario de grupos y ministerios
  static Future<void> _removeUserFromCollections(String userId) async {
    debugPrint('🗑️ Removendo usuário de grupos e ministérios...');
    
    final userPath = '/users/$userId';

    // Remover de grupos
    final groups = await _firestore.collection('groups').get();
    for (var group in groups.docs) {
      await _removeUserFromDocument(group, userId, userPath);
    }

    // Remover de ministerios
    final ministries = await _firestore.collection('ministries').get();
    for (var ministry in ministries.docs) {
      await _removeUserFromDocument(ministry, userId, userPath);
    }
  }

  /// Helper para remover usuario de un documento específico
  static Future<void> _removeUserFromDocument(
    QueryDocumentSnapshot doc, 
    String userId, 
    String userPath
  ) async {
    try {
      final data = doc.data() as Map<String, dynamic>;
      bool hasChanges = false;
      
      // Verificar y limpiar array 'members'
      if (data.containsKey('members') && data['members'] is List) {
        final List<dynamic> members = List.from(data['members']);
        final originalLength = members.length;
        
        members.removeWhere((member) => 
          member.toString() == userPath || 
          member.toString() == userId ||
          (member is DocumentReference && member.id == userId)
        );
        
        if (members.length != originalLength) {
          data['members'] = members;
          hasChanges = true;
        }
      }

      // Verificar otros campos que pueden contener referencias del usuario
      final fieldsToCheck = ['adminIds', 'ministrieAdmin', 'ministryAdmin', 'groupAdmin'];
      for (String field in fieldsToCheck) {
        if (data.containsKey(field)) {
          if (data[field] is List) {
            final List<dynamic> fieldList = List.from(data[field]);
            final originalLength = fieldList.length;
            
            fieldList.removeWhere((item) => 
              item.toString() == userPath || 
              item.toString() == userId ||
              (item is DocumentReference && item.id == userId)
            );
            
            if (fieldList.length != originalLength) {
              data[field] = fieldList;
              hasChanges = true;
            }
          } else if (data[field].toString() == userId || data[field].toString() == userPath) {
            data[field] = null;
            hasChanges = true;
          }
        }
      }

      // Solo actualizar si hay cambios
      if (hasChanges) {
        await doc.reference.update(data);
        debugPrint('✅ Usuario removido de ${doc.reference.path}');
      }
    } catch (e) {
      debugPrint('⚠️ Error al remover usuario de ${doc.reference.path}: $e');
      // No lanzar error para no interrumpir el proceso
    }
  }

  /// Elimina otros datos relacionados del usuario
  static Future<void> _deleteRelatedUserData(String userId) async {
    debugPrint('🗑️ Eliminando datos relacionados...');
    
    try {
      // Lista de colecciones a limpiar
      final collectionsToClean = [
        'counseling_requests',
        'private_prayer_requests',
        'event_attendance',
        'course_enrollments',
        'prayer_requests',
        'announcements', // Si el usuario creó anuncios
        'user_notifications',
      ];

      for (String collectionName in collectionsToClean) {
        try {
          final docs = await _firestore
              .collection(collectionName)
              .where('userId', isEqualTo: userId)
              .get();
          
          for (var doc in docs.docs) {
            await doc.reference.delete();
          }
          
          if (docs.docs.isNotEmpty) {
            debugPrint('✅ Eliminados ${docs.docs.length} documentos de $collectionName');
          }
        } catch (e) {
          debugPrint('⚠️ Error al limpiar $collectionName: $e');
          // Continuar con la siguiente colección
        }
      }

      // Limpiar subcoleções del usuario
      try {
        final userDoc = _firestore.collection('users').doc(userId);
        
        // Eliminar historial de login
        final loginHistory = await userDoc.collection('login_history').get();
        for (var doc in loginHistory.docs) {
          await doc.reference.delete();
        }
        
        if (loginHistory.docs.isNotEmpty) {
          debugPrint('✅ Eliminado historial de login (${loginHistory.docs.length} registros)');
        }
      } catch (e) {
        debugPrint('⚠️ Error al limpiar subcoleções: $e');
      }

    } catch (e) {
      debugPrint('⚠️ Erro ao eliminar alguns dados relacionados: $e');
      // No lanzar el error para no interrumpir el proceso principal
    }
  }
}
