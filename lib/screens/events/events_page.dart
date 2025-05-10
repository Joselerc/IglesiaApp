import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import '../../models/event_model.dart';
import './create/create_event_modal.dart';
import './event_detail_screen.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../services/auth_service.dart';
import '../../services/permission_service.dart';
import 'package:provider/provider.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  String _selectedFilter = 'Próximos';
  final List<String> _filterOptions = ['Próximos', 'Esta semana', 'Este mês', 'Todos'];
  
  // Estado para saber si el usuario puede crear eventos
  bool _canCreateEvents = false;
  
  @override
  void initState() {
    super.initState();
    initializeDateFormatting('pt_BR', null);
    // Verificamos el permiso del usuario al iniciar
    _checkCreatePermission();
  }
  
  Future<void> _checkCreatePermission() async {
    final permissionService = PermissionService();
    final hasPermission = await permissionService.hasPermission('create_events');
    if (mounted) {
      setState(() {
        _canCreateEvents = hasPermission;
      });
    }
  }
  
  Query<Map<String, dynamic>> _getFilteredQuery() {
    final baseQuery = FirebaseFirestore.instance
        .collection('events')
        .where('isActive', isEqualTo: true);
        
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case 'Próximos':
        return baseQuery
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .orderBy('startDate', descending: false)
            .limit(20);
      case 'Esta semana':
        final endOfWeek = DateTime(now.year, now.month, now.day + (7 - now.weekday));
        return baseQuery
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
            .orderBy('startDate', descending: false);
      case 'Este mês':
        final endOfMonth = DateTime(now.year, now.month + 1, 0);
        return baseQuery
            .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
            .where('startDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
            .orderBy('startDate', descending: false);
      case 'Todos':
      default:
        return baseQuery
            .orderBy('startDate', descending: false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // AppBar mejorado
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            floating: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Eventos',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.7),
                          AppColors.primary,
                        ],
                      ),
                    ),
                  ),
                  // Patrón decorativo
                  Positioned(
                    right: -50,
                    top: -50,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                  Positioned(
                    left: -30,
                    bottom: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              // Mostrar el botón de añadir solo si tiene permiso para crear eventos
              if (_canCreateEvents)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                    tooltip: 'Criar Evento',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => Padding(
                          padding: EdgeInsets.only(
                            top: MediaQuery.of(context).padding.top + 10,
                          ),
                          child: FractionallySizedBox(
                            heightFactor: 0.92,
                            child: const CreateEventModal(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
          
          // Filtros mejorados
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtrar por:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            checkmarkColor: Colors.white,
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.grey.shade100,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedFilter = filter;
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Lista de eventos
          StreamBuilder<QuerySnapshot>(
            stream: _getFilteredQuery().snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                        const SizedBox(height: 16),
                        Text('Erro: ${snapshot.error}'),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: _buildEmptyState(),
                );
              }

              final events = snapshot.data!.docs
                  .map((doc) => EventModel.fromFirestore(doc))
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildEventCard(events[index]),
                    childCount: events.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Mostrar el FAB solo si tiene permiso para crear eventos
      floatingActionButton: _canCreateEvents
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                    ),
                    child: FractionallySizedBox(
                      heightFactor: 0.92,
                      child: const CreateEventModal(),
                    ),
                  ),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
              tooltip: 'Criar Evento',
            )
          : null, // Ocultar si no tiene permiso
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(
              Icons.event_busy,
              size: 80,
              color: AppColors.primary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nenhum evento encontrado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // El texto de crear evento solo aparece si tiene permiso
          if (_canCreateEvents)
            Text(
              'Tente outro filtro ou crie um novo evento',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            )
          else
            Text(
              'Tente selecionar outro filtro',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 24),
          // El botón de crear evento solo aparece si tiene permiso
          if (_canCreateEvents)
            ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => Padding(
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                    ),
                    child: FractionallySizedBox(
                      heightFactor: 0.92,
                      child: const CreateEventModal(),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Criar Evento'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildEventCard(EventModel event) {
    // Formateo de fecha y hora con intl
    final dateFormat = DateFormat('EEEE, d MMMM', 'pt_BR');
    final timeFormat = DateFormat('HH:mm', 'pt_BR');
    final eventDate = dateFormat.format(event.startDate);
    final eventTime = "${timeFormat.format(event.startDate)} - ${timeFormat.format(event.endDate)}";
    
    // Preparar dirección formateada
    String locationText = "Sem localização";
    if (event.eventType == 'online') {
      locationText = "Evento online";
    } else if (event.city != null && event.street != null) {
      locationText = "${event.street}, ${event.city}";
      if (event.number != null) {
        locationText = "${event.street} ${event.number}, ${event.city}";
      }
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen con overlay
            Stack(
              children: [
                if (event.imageUrl.isNotEmpty)
                  Hero(
                    tag: 'event-image-${event.id}',
                    child: Image.network(
                      event.imageUrl,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: AppColors.primary.withOpacity(0.1),
                          child: Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              size: 42,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Container(
                    height: 200,
                    color: AppColors.primary.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        Icons.event,
                        size: 64,
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                  
                // Gradiente
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                        stops: const [0.6, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Etiqueta de tipo de evento
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getEventTypeColor(event.eventType),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getEventTypeIcon(event.eventType),
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getEventTypeLabel(event.eventType),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Fecha del evento estilizada
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      // Badge de fecha
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              event.startDate.day.toString(),
                              style: TextStyle(
                                fontSize: 24,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              DateFormat('MMM', 'pt_BR').format(event.startDate).substring(0, 3).toUpperCase(),
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Título del evento
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                shadows: [
                                  Shadow(
                                    offset: Offset(0, 1),
                                    blurRadius: 3,
                                    color: Colors.black54,
                                  ),
                                ],
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
              ],
            ),
            
            // Detalles del evento
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha y hora con íconos
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.event, size: 18, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              eventDate.capitalize(),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              eventTime,
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Ubicación con ícono
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          event.eventType == 'online' ? Icons.language : Icons.location_on,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          locationText,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  if (event.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    
                    // Descripción
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Acciones
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (event.hasTickets)
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EventDetailScreen(event: event),
                              ),
                            );
                          },
                          icon: const Icon(Icons.confirmation_number, size: 16),
                          label: const Text('Ingressos'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        )
                      else
                        const SizedBox(),
                        
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EventDetailScreen(event: event),
                            ),
                          );
                        },
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Ver Detalhes'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  IconData _getEventTypeIcon(String eventType) {
    switch (eventType) {
      case 'online':
        return Icons.videocam;
      case 'hybrid':
        return Icons.devices;
      case 'presential':
      default:
        return Icons.location_on;
    }
  }
  
  Color _getEventTypeColor(String eventType) {
    switch (eventType) {
      case 'online':
        return Colors.purple;
      case 'hybrid':
        return Colors.teal;
      case 'presential':
      default:
        return Colors.blue;
    }
  }
  
  String _getEventTypeLabel(String eventType) {
    switch (eventType) {
      case 'online':
        return 'Online';
      case 'hybrid':
        return 'Híbrido';
      case 'presential':
      default:
        return 'Presencial';
    }
  }
}

// Extensión para capitalizar texto
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1)}";
  }
} 