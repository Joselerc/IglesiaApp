import 'package:flutter/material.dart';
import '../../models/notification.dart';

class NotificationTypeFilter extends StatelessWidget {
  final NotificationType? selectedFilter;
  final Function(NotificationType?) onFilterSelected;

  const NotificationTypeFilter({
    super.key,
    required this.selectedFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filtrar por tipo',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (selectedFilter != null)
                TextButton(
                  onPressed: () => onFilterSelected(null),
                  child: const Text('Remover filtro'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Anuncios
                  _buildCategoryHeader('Anúncios', Icons.announcement, Colors.amber),
                  _buildFilterTile(
                    context,
                    NotificationType.newAnnouncement,
                    'Anúncios gerais',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.newCultAnnouncement,
                    'Anúncios de cultos',
                  ),
                  const Divider(),
                  
                  // Ministerios
                  _buildCategoryHeader('Ministérios', Icons.people, Colors.blue),
                  _buildFilterTile(
                    context,
                    NotificationType.newMinistry,
                    'Novos ministérios',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryJoinRequest,
                    'Solicitações para entrar',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryJoinRequestAccepted,
                    'Solicitações aprovadas',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewEvent,
                    'Eventos dos ministérios',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewPost,
                    'Publicações dos ministérios',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewWorkSchedule,
                    'Escalas de trabalho',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.ministryNewChat,
                    'Mensagens dos ministérios',
                  ),
                  const Divider(),
                  
                  // Grupos
                  _buildCategoryHeader('Grupos', Icons.group, Colors.green),
                  _buildFilterTile(
                    context,
                    NotificationType.newGroup,
                    'Novos grupos',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupJoinRequest,
                    'Solicitações para entrar',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupJoinRequestAccepted,
                    'Solicitações aprovadas',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupNewEvent,
                    'Eventos dos grupos',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupNewPost,
                    'Publicações dos grupos',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.groupNewChat,
                    'Mensagens dos grupos',
                  ),
                  const Divider(),
                  
                  // Oraciones
                  _buildCategoryHeader('Orações', Icons.healing, Colors.purple),
                  _buildFilterTile(
                    context,
                    NotificationType.newPrivatePrayer,
                    'Pedidos de oração particular',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.privatePrayerPrayed,
                    'Orações completadas',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.publicPrayerAccepted,
                    'Orações públicas aprovadas',
                  ),
                  const Divider(),
                  
                  // Eventos
                  _buildCategoryHeader('Eventos', Icons.event, Colors.orange),
                  _buildFilterTile(
                    context,
                    NotificationType.newEvent,
                    'Novos eventos',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.eventReminder,
                    'Lembretes de eventos',
                  ),
                  const Divider(),
                  
                  // Consejería
                  _buildCategoryHeader('Aconselhamento', Icons.support_agent, Colors.teal),
                  _buildFilterTile(
                    context,
                    NotificationType.newCounselingRequest,
                    'Novos pedidos',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.counselingAccepted,
                    'Agendamentos confirmados',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.counselingRejected,
                    'Agendamentos rejeitados',
                  ),
                  _buildFilterTile(
                    context,
                    NotificationType.counselingCancelled,
                    'Agendamentos cancelados',
                  ),
                  const Divider(),
                  
                  // Videos
                  _buildCategoryHeader('Vídeos', Icons.video_library, Colors.red),
                  _buildFilterTile(
                    context,
                    NotificationType.newVideo,
                    'Novos vídeos',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTile(
    BuildContext context,
    NotificationType type,
    String title,
  ) {
    final isSelected = selectedFilter == type;
    
    return ListTile(
      title: Text(title),
      leading: Radio<NotificationType>(
        value: type,
        groupValue: selectedFilter,
        onChanged: (value) => onFilterSelected(value),
      ),
      selected: isSelected,
      onTap: () => onFilterSelected(type),
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      dense: true,
    );
  }
} 