import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../models/private_prayer.dart';

class PrivatePrayerDetailModal extends StatelessWidget {
  final PrivatePrayer prayer;

  const PrivatePrayerDetailModal({
    super.key,
    required this.prayer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de la Oración'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta principal con la petición
            Card(
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Pastor info
                        FutureBuilder<DocumentSnapshot>(
                          future: (prayer.acceptedBy ?? prayer.pastorId)?.get(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const CircularProgressIndicator();
                            }
                            
                            final userData = snapshot.data!.data() as Map<String, dynamic>?;
                            final pastorName = userData?['displayName'] ?? 'Pastor';
                            final photoUrl = userData?['photoUrl'] as String?;
                            
                            return Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                  child: photoUrl == null ? const Icon(Icons.person) : null,
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pastorName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Recibida: ${timeago.format(prayer.createdAt, locale: 'es')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                        
                        const Spacer(),
                        
                        // Status badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: prayer.pastorResponse != null 
                                ? Colors.green[100] 
                                : prayer.isAccepted 
                                    ? Colors.blue[100]
                                    : Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            prayer.pastorResponse != null 
                                ? 'Respondido'
                                : prayer.isAccepted 
                                    ? 'Aceptado' 
                                    : 'Pendiente',
                            style: TextStyle(
                              color: prayer.pastorResponse != null 
                                  ? Colors.green[800]
                                  : prayer.isAccepted 
                                      ? Colors.blue[800]
                                      : Colors.orange[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Petición de oración
                    const Text(
                      'Tu petición de oración:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Text(
                        prayer.content,
                        style: const TextStyle(fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sección de programación
            if (prayer.isAccepted && prayer.scheduledAt != null) ...[
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            prayer.selectedMethod == 'call' ? Icons.phone : 
                            prayer.selectedMethod == 'whatsapp' ? Icons.chat :
                            prayer.selectedMethod == 'inperson' ? Icons.person : 
                            Icons.event,
                            color: Colors.green[700],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Oración programada',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Método seleccionado
                      if (prayer.selectedMethod != null) ...[
                        Row(
                          children: [
                            const Text(
                              'Método: ',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              prayer.selectedMethod == 'call' ? 'Llamada' : 
                              prayer.selectedMethod == 'whatsapp' ? 'WhatsApp' : 
                              prayer.selectedMethod == 'inperson' ? 'En persona' : 
                              prayer.selectedMethod ?? 'No especificado',
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                      ],
                      
                      // Fecha y hora
                      Row(
                        children: [
                          const Text(
                            'Fecha: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${prayer.scheduledAt!.day}/${prayer.scheduledAt!.month}/${prayer.scheduledAt!.year}',
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Text(
                            'Hora: ',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${prayer.scheduledAt!.hour.toString().padLeft(2, '0')}:${prayer.scheduledAt!.minute.toString().padLeft(2, '0')}',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
            
            // Sección de respuesta
            if (prayer.pastorResponse != null) ...[
              Card(
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.message,
                            color: theme.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Respuesta del pastor',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: theme.primaryColor,
                              fontSize: 16,
                            ),
                          ),
                          const Spacer(),
                          if (prayer.respondedAt != null)
                            Text(
                              timeago.format(prayer.respondedAt!, locale: 'es'),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        prayer.pastorResponse!,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 