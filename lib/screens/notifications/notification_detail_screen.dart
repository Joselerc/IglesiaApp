import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/notification.dart';
import 'package:provider/provider.dart';
import '../../services/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';

class NotificationDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const NotificationDetailScreen({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    // Inicializar formato de fecha para portugués si no se ha hecho
    try {
      initializeDateFormatting('pt_BR');
    } catch(e) {
      print('Erro ao inicializar formato pt_BR: $e');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhe da notificação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Excluir notificação',
            onPressed: () async {
              final notificationService = Provider.of<NotificationService>(context, listen: false);
              
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Excluir notificação'),
                  content: const Text('Tem certeza que deseja excluir esta notificação?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Excluir'),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                try {
                  await notificationService.deleteNotification(notification.id);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificação excluída'),
                      ),
                    );
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Erro ao excluir: $e'),
                      ),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado con icono y tipo
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: notification.getColor().withOpacity(0.2),
                  radius: 24,
                  child: Icon(
                    notification.getIcon(),
                    color: notification.getColor(),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNotificationTypeName(notification.type),
                        style: TextStyle(
                          color: notification.getColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Fecha y hora
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat("EEEE, d 'de' MMMM 'de' y, HH:mm", 'pt_BR')
                        .format(notification.createdAt),
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contenido
            const Text(
              'Mensagem',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              notification.message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
              ),
            ),
            
            // Información adicional si existe (filtrando IDs)
            if (notification.data.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Informações adicionais',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...notification.data.entries
                  .where((entry) => !entry.key.toLowerCase().endsWith('id')) 
                  .map((entry) {
                 return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.key}: ',
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          '${entry.value}',
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
            
            const SizedBox(height: 32),
            
            // Botón para navegar a la acción relacionada si existe
            if (notification.actionRoute != null)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, notification.actionRoute!);
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Ver detalhes'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  String _getNotificationTypeName(NotificationType type) {
    // Traducciones al portugués de Brasil
    switch (type) {
      // Anúncios
      case NotificationType.newAnnouncement:
        return 'Novo anúncio';
      case NotificationType.newCultAnnouncement:
        return 'Novo anúncio de culto';
      
      // Ministérios
      case NotificationType.newMinistry:
        return 'Novo ministério';
      case NotificationType.ministryJoinRequestAccepted:
        return 'Solicitação de ministério aceita';
      case NotificationType.ministryJoinRequestRejected:
        return 'Solicitação de ministério rejeitada';
      case NotificationType.ministryJoinRequest:
        return 'Solicitação para entrar no ministério';
      case NotificationType.ministryManuallyAdded:
        return 'Adicionado ao ministério';
      case NotificationType.ministryNewEvent:
        return 'Novo evento do ministério';
      case NotificationType.ministryNewPost:
        return 'Nova publicação no ministério';
      case NotificationType.ministryNewWorkSchedule:
        return 'Nova escala de trabalho';
      case NotificationType.ministryWorkScheduleAccepted:
        return 'Escala de trabalho aceita';
      case NotificationType.ministryWorkScheduleRejected:
        return 'Escala de trabalho rejeitada';
      case NotificationType.ministryWorkSlotFilled:
        return 'Vaga de trabalho preenchida';
      case NotificationType.ministryWorkSlotAvailable:
        return 'Vaga de trabalho disponível';
      case NotificationType.ministryEventReminder:
        return 'Lembrete de evento do ministério';
      case NotificationType.ministryNewChat:
        return 'Nova mensagem no ministério';
      case NotificationType.ministryPromotedToAdmin:
        return 'Promovido a admin do ministério';
      
      // Grupos
      case NotificationType.newGroup:
        return 'Novo grupo';
      case NotificationType.groupJoinRequestAccepted:
        return 'Solicitação de grupo aceita';
      case NotificationType.groupJoinRequestRejected:
        return 'Solicitação de grupo rejeitada';
      case NotificationType.groupJoinRequest:
        return 'Solicitação para entrar no grupo';
      case NotificationType.groupManuallyAdded:
        return 'Adicionado ao grupo';
      case NotificationType.groupNewEvent:
        return 'Novo evento do grupo';
      case NotificationType.groupNewPost:
        return 'Nova publicação no grupo';
      case NotificationType.groupEventReminder:
        return 'Lembrete de evento do grupo';
      case NotificationType.groupNewChat:
        return 'Nova mensagem no grupo';
      case NotificationType.groupPromotedToAdmin:
        return 'Promovido a admin do grupo';
      
      // Orações
      case NotificationType.newPrivatePrayer:
        return 'Novo pedido de oração particular';
      case NotificationType.privatePrayerPrayed:
        return 'Oração particular completada';
      case NotificationType.publicPrayerAccepted:
        return 'Oração pública aceita';
      
      // Eventos
      case NotificationType.newEvent:
        return 'Novo evento';
      case NotificationType.eventReminder:
        return 'Lembrete de evento';
      
      // Aconselhamento
      case NotificationType.newCounselingRequest:
        return 'Novo pedido de aconselhamento';
      case NotificationType.counselingAccepted:
        return 'Agendamento confirmado';
      case NotificationType.counselingRejected:
        return 'Agendamento rejeitado';
      case NotificationType.counselingCancelled:
        return 'Agendamento cancelado';
      
      // Vídeos
      case NotificationType.newVideo:
        return 'Novo vídeo';
      
      // Outros
      case NotificationType.message:
        return 'Mensagem';
      case NotificationType.generic:
        return 'Notificação';
      case NotificationType.custom:
        return 'Notificação personalizada';
      default:
        return 'Notificação'; // Fallback genérico
    }
  }
} 