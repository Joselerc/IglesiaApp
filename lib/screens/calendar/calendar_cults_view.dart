import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/cult.dart';
import '../../services/event_service.dart';
import '../../theme/app_colors.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

class CalendarCultsView extends StatelessWidget {
  final DateTime selectedDate;

  const CalendarCultsView({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('cults')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Erro: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Não há cultos programados',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        // Obtener cultos
        final allCults = snapshot.data!.docs
            .map((doc) {
              try {
                return Cult.fromFirestore(doc);
              } catch (e) {
                print('Erro ao converter culto: $e');
                return null;
              }
            })
            .where((cult) => cult != null)
            .cast<Cult>()
            .toList();

        // Filtrar cultos para la fecha seleccionada
        final cultsForSelectedDate = allCults.where((cult) {
          return cult.date.year == selectedDate.year &&
              cult.date.month == selectedDate.month &&
              cult.date.day == selectedDate.day;
        }).toList();

        if (cultsForSelectedDate.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Não há cultos para ${DateFormat('d MMMM yyyy', 'pt_BR').format(selectedDate)}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cultsForSelectedDate.length,
          itemBuilder: (context, index) {
            final cult = cultsForSelectedDate[index];
            return _buildCultCard(context, cult);
          },
        );
      },
    );
  }

  Widget _buildCultCard(BuildContext context, Cult cult) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showCultDetailsDialog(context, cult);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera con degradado y estado del culto
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.8),
                  ],
                ),
              ),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.church, 
                        color: Colors.white.withOpacity(0.9),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE', 'pt_BR').format(cult.date),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getStatusText(cult.status),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del culto
                  Text(
                    cult.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Fecha del culto
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('d MMMM yyyy', 'pt_BR').format(cult.date),
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Hora de inicio y fin
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${DateFormat('HH:mm').format(cult.startTime)} - ${DateFormat('HH:mm').format(cult.endTime)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Ubicación del culto
                  FutureBuilder<String>(
                    future: _getLocationName(cult),
                    builder: (context, snapshot) {
                      String locationName = "Igreja";
                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        locationName = snapshot.data!;
                      }
                      
                      return Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationName,
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      );
                    }
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  String _getStatusText(String status) {
    switch (status) {
      case 'planificado':
        return 'Planejado';
      case 'en_curso':
        return 'Em curso';
      case 'finalizado':
        return 'Finalizado';
      default:
        return status;
    }
  }
  
  Color _getStatusColor(String status) {
    switch (status) {
      case 'planificado':
        return Colors.amber;
      case 'en_curso':
        return Colors.green;
      case 'finalizado':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  // Método para añadir un recordatorio del culto
  void _addReminder(BuildContext context, Cult cult) async {
    try {
      // Obtener el nombre de la iglesia
      final churchDoc = await FirebaseFirestore.instance
          .collection('churches')
          .doc(cult.churchId)
          .get();
      
      final churchName = churchDoc.exists 
          ? (churchDoc.data() as Map<String, dynamic>)['name'] ?? 'Igreja'
          : 'Igreja';
      
      await EventService().addEventReminder(
        eventId: cult.id,
        eventTitle: cult.name,
        eventDate: cult.date,
        eventType: 'cult',
        entityId: cult.churchId ?? '',
        entityName: churchName,
      );
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lembrete adicionado com sucesso'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao configurar lembrete: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Método para obtener el nombre de la ubicación
  Future<String> _getLocationName(Cult cult) async {
    try {
      // Buscar el documento del culto para obtener campos adicionales como locationId o location
      final cultDoc = await FirebaseFirestore.instance
          .collection('cults')
          .doc(cult.id)
          .get();
      
      if (!cultDoc.exists) return 'Igreja';
      
      final cultData = cultDoc.data() as Map<String, dynamic>;
      
      // Verificar si hay un locationId (referencia a churchLocations)
      if (cultData.containsKey('locationId') && cultData['locationId'] != null) {
        DocumentReference locationRef = cultData['locationId'];
        try {
          final locationDoc = await locationRef.get();
          if (locationDoc.exists) {
            final locationData = locationDoc.data() as Map<String, dynamic>?;
            return locationData?['name'] ?? 'Igreja';
          }
        } catch (e) {
          debugPrint('Error al obtener ubicación por referencia: $e');
        }
      }
      
      // Verificar si hay un objeto location embebido
      if (cultData.containsKey('location') && cultData['location'] != null) {
        final location = cultData['location'] as Map<String, dynamic>?;
        if (location != null && location.containsKey('name')) {
          return location['name'] ?? 'Igreja';
        }
      }
      
      return 'Igreja';
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      return 'Igreja';
    }
  }

  // Muestra un diálogo con los detalles del culto
  void _showCultDetailsDialog(BuildContext context, Cult cult) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _getLocationDetails(cult),
          builder: (context, snapshot) {
            // Información de ubicación por defecto
            Map<String, dynamic> locationInfo = {
              'name': 'Igreja',
              'formattedAddress': '',
              'street': '',
              'number': '',
              'complement': '',
              'neighborhood': '',
              'city': '',
              'state': '',
              'postalCode': '',
              'country': ''
            };
            
            if (snapshot.hasData) {
              locationInfo = snapshot.data!;
            }
            
            // Construir la dirección completa
            final List<String> addressParts = [];
            if (locationInfo['street']?.isNotEmpty ?? false) {
              addressParts.add('${locationInfo['street']}');
              if (locationInfo['number']?.isNotEmpty ?? false) {
                addressParts.last += ', ${locationInfo['number']}';
              }
            }
            if (locationInfo['complement']?.isNotEmpty ?? false) {
              addressParts.add('${locationInfo['complement']}');
            }
            if (locationInfo['neighborhood']?.isNotEmpty ?? false) {
              addressParts.add('${locationInfo['neighborhood']}');
            }
            if (locationInfo['city']?.isNotEmpty ?? false) {
              String cityState = locationInfo['city'];
              if (locationInfo['state']?.isNotEmpty ?? false) {
                cityState += ' - ${locationInfo['state']}';
              }
              addressParts.add(cityState);
            }
            if (locationInfo['postalCode']?.isNotEmpty ?? false) {
              addressParts.add('CEP: ${locationInfo['postalCode']}');
            }
            if (locationInfo['country']?.isNotEmpty ?? false) {
              addressParts.add('${locationInfo['country']}');
            }
            
            final String fullAddress = addressParts.join('\n');
            final String formattedAddress = addressParts.isEmpty ? 'Igreja' : addressParts.join(', ');
            
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cabecera con gradiente
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary,
                            AppColors.primary,
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  cult.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('EEEE, dd MMMM yyyy', 'pt_BR').format(cult.date).toLowerCase(),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contenido
                    Padding(
                      padding: const EdgeInsets.all(0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hora
                          Container(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.access_time,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Horário",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      '${DateFormat('HH:mm').format(cult.startTime)} - ${DateFormat('HH:mm').format(cult.endTime)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          // Localización
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border(
                                top: BorderSide(color: Colors.grey.shade200, width: 1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Localização",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      SelectableText(
                                        locationInfo['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Botón de cerrar
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Fechar'),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  // Método para obtener los detalles completos de la ubicación
  Future<Map<String, dynamic>> _getLocationDetails(Cult cult) async {
    Map<String, dynamic> defaultLocation = {
      'name': 'Igreja',
      'formattedAddress': '',
      'street': '',
      'number': '',
      'complement': '',
      'neighborhood': '',
      'city': '',
      'state': '',
      'postalCode': '',
      'country': ''
    };
    
    try {
      // Buscar el documento del culto para obtener campos adicionales como locationId o location
      final cultDoc = await FirebaseFirestore.instance
          .collection('cults')
          .doc(cult.id)
          .get();
      
      if (!cultDoc.exists) return defaultLocation;
      
      final cultData = cultDoc.data() as Map<String, dynamic>;
      
      // Verificar si hay un locationId (referencia a churchLocations)
      if (cultData.containsKey('locationId') && cultData['locationId'] != null) {
        DocumentReference locationRef = cultData['locationId'];
        try {
          final locationDoc = await locationRef.get();
          if (locationDoc.exists) {
            final locationData = locationDoc.data() as Map<String, dynamic>?;
            if (locationData != null) {
              return {
                'name': locationData['name'] ?? 'Igreja',
                'street': locationData['street'] ?? '',
                'number': locationData['number'] ?? '',
                'complement': locationData['complement'] ?? '',
                'neighborhood': locationData['neighborhood'] ?? '',
                'city': locationData['city'] ?? '',
                'state': locationData['state'] ?? '',
                'postalCode': locationData['postalCode'] ?? '',
                'country': locationData['country'] ?? '',
                'formattedAddress': ''
              };
            }
          }
        } catch (e) {
          debugPrint('Error al obtener ubicación por referencia: $e');
        }
      }
      
      // Verificar si hay un objeto location embebido
      if (cultData.containsKey('location') && cultData['location'] != null) {
        final location = cultData['location'] as Map<String, dynamic>?;
        if (location != null) {
          return {
            'name': location['name'] ?? 'Igreja',
            'street': location['street'] ?? '',
            'number': location['number'] ?? '',
            'complement': location['complement'] ?? '',
            'neighborhood': location['neighborhood'] ?? '',
            'city': location['city'] ?? '',
            'state': location['state'] ?? '',
            'postalCode': location['postalCode'] ?? '',
            'country': location['country'] ?? '',
            'formattedAddress': ''
          };
        }
      }
      
      return defaultLocation;
    } catch (e) {
      debugPrint('Erro ao obter detalhes da localização: $e');
      return defaultLocation;
    }
  }
  
  // Método para copiar texto al portapapeles
  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Endereço copiado para a área de transferência'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
} 