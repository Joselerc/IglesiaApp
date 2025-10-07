import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/private_prayer.dart';
import '../../../services/prayer_service.dart';
import '../../../l10n/app_localizations.dart';

class RespondPrayerModal extends StatefulWidget {
  final PrivatePrayer prayer;
  
  const RespondPrayerModal({
    super.key,
    required this.prayer,
  });

  @override
  State<RespondPrayerModal> createState() => _RespondPrayerModalState();
}

class _RespondPrayerModalState extends State<RespondPrayerModal> {
  final _formKey = GlobalKey<FormState>();
  final _responseController = TextEditingController();
  final _prayerService = PrayerService();
  bool _isLoading = false;
  bool _isSavingMessage = false;
  bool _isLoadingMessages = true;
  String? _errorMessage;
  String? _successMessage;
  List<Map<String, String>> _predefinedMessages = [];

  @override
  void initState() {
    super.initState();
    _loadPredefinedMessages();
    
    // Si ya hay una respuesta, mostrarla en el campo de texto
    if (widget.prayer.pastorResponse != null) {
      _responseController.text = widget.prayer.pastorResponse!;
    }
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _loadPredefinedMessages() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('predefined_messages')
          .orderBy('createdAt', descending: true)
          .get();

      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'content': data['content'] as String? ?? '',
        };
      }).toList();

      setState(() {
        _predefinedMessages = messages;
        _isLoadingMessages = false;
      });
    } catch (e) {
      print('Error cargando mensajes predefinidos: $e');
    }
  }

  Future<void> _submitResponse() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Usar el servicio para responder la oración
      final success = await _prayerService.respondPrivatePrayer(
        widget.prayer.id,
        _responseController.text.trim(),
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.responseSentSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.errorSendingResponse),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.error}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveAsPredefinedMessage() async {
    final messageContent = _responseController.text.trim();
    if (messageContent.isEmpty) {
      setState(() {
        _errorMessage = 'No puedes guardar un mensaje vacío';
      });
      return;
    }

    setState(() {
      _isSavingMessage = true;
      _errorMessage = null;
      _successMessage = null;
    });
    
    try {
      final success = await _prayerService.createPredefinedMessage(messageContent);
      
      if (success && mounted) {
        setState(() {
          _successMessage = 'Mensaje guardado correctamente';
          _isSavingMessage = false;
        });
        // Recargar los mensajes predefinidos
        await _loadPredefinedMessages();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Error al guardar el mensaje';
          _isSavingMessage = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isSavingMessage = false;
      });
    }
  }

  void _selectPredefinedMessage(String message) {
    setState(() {
      _responseController.text = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.respondPrayer),
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
            // Información del solicitante
            StreamBuilder<DocumentSnapshot>(
              stream: widget.prayer.userId.snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Text(AppLocalizations.of(context)!.loadingRequesterData);
                }
                
                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final userName = userData?['displayName'] ?? AppLocalizations.of(context)!.user;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundImage: userData?['photoUrl'] != null
                              ? NetworkImage(userData!['photoUrl'])
                              : null,
                          child: userData?['photoUrl'] == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              if (userData?['email'] != null)
                                Text(
                                  userData!['email'],
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            // Contenido de la oración
            Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.prayerRequest2,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.prayer.content),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          AppLocalizations.of(context)!.receivedOn(
                            DateFormat('dd/MM/yyyy', Localizations.localeOf(context).toString()).format(widget.prayer.createdAt)
                          ),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sección de mensajes predefinidos
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.predefinedMessages2,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.blue[700],
                  ),
                  onPressed: _loadPredefinedMessages,
                  tooltip: AppLocalizations.of(context)!.reloadMessages,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            if (_isLoadingMessages)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_predefinedMessages.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    AppLocalizations.of(context)!.noPredefinedMessages,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _predefinedMessages.length,
                  itemBuilder: (context, index) {
                    final message = _predefinedMessages[index];
                    return Card(
                      margin: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _selectPredefinedMessage(message['content']!),
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(12),
                          child: Text(
                            message['content']!,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Formulario de respuesta
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.yourResponse,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _responseController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)!.writeYourResponseHere,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Por favor ingresa una respuesta';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _submitResponse,
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(AppLocalizations.of(context)!.sendResponse),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
} 