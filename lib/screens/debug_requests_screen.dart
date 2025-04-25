import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DebugRequestsScreen extends StatefulWidget {
  const DebugRequestsScreen({Key? key}) : super(key: key);

  @override
  State<DebugRequestsScreen> createState() => _DebugRequestsScreenState();
}

class _DebugRequestsScreenState extends State<DebugRequestsScreen> {
  final _idController = TextEditingController();
  String? _entityType;
  bool _isLoading = false;
  List<Map<String, dynamic>> _requests = [];
  
  @override
  void dispose() {
    _idController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAllRequests() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('membership_requests')
          .orderBy('requestTimestamp', descending: true)
          .limit(50)
          .get();
          
      _processRequests(querySnapshot);
    } catch (e) {
      _showError('Error cargando solicitudes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadFilteredRequests() async {
    if (_idController.text.isEmpty) {
      _showError('Ingresa un ID de entidad');
      return;
    }
    
    if (_entityType == null) {
      _showError('Selecciona un tipo de entidad');
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('membership_requests')
          .where('entityId', isEqualTo: _idController.text)
          .where('entityType', isEqualTo: _entityType)
          .orderBy('requestTimestamp', descending: true)
          .get();
          
      _processRequests(querySnapshot);
    } catch (e) {
      _showError('Error cargando solicitudes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  void _processRequests(QuerySnapshot snapshot) {
    final requests = <Map<String, dynamic>>[];
    
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      requests.add({
        'id': doc.id,
        'entityId': data['entityId'],
        'entityType': data['entityType'],
        'entityName': data['entityName'],
        'userId': data['userId'],
        'userName': data['userName'],
        'status': data['status'],
        'requestTimestamp': data['requestTimestamp'] is Timestamp 
            ? (data['requestTimestamp'] as Timestamp).toDate() 
            : null,
        'message': data['message'],
      });
    }
    
    setState(() {
      _requests = requests;
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Depurador de Solicitudes'),
      ),
      body: Column(
        children: [
          // Panel de filtros
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              children: [
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: 'ID de entidad',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: grupoxyz123',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _entityType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de entidad',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'group',
                      child: Text('Grupo'),
                    ),
                    DropdownMenuItem(
                      value: 'ministry',
                      child: Text('Ministerio'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _entityType = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loadFilteredRequests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Buscar Filtrado'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _loadAllRequests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Ver Todas'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Resultados
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _requests.isEmpty
                    ? const Center(child: Text('No se encontraron solicitudes'))
                    : ListView.builder(
                        itemCount: _requests.length,
                        itemBuilder: (context, index) {
                          final request = _requests[index];
                          final requestDate = request['requestTimestamp'];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: ListTile(
                              title: Text(
                                '${request['userName']} → ${request['entityName']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Status: ${request['status']}'),
                                  Text('UserId: ${request['userId']}'),
                                  Text('EntityId: ${request['entityId']}'),
                                  Text('Tipo: ${request['entityType']}'),
                                  if (requestDate != null)
                                    Text(
                                      'Fecha: ${DateFormat('dd/MM/yyyy HH:mm').format(requestDate)}',
                                    ),
                                  if (request['message'] != null)
                                    Text('Mensaje: ${request['message']}'),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
} 