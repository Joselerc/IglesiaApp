import 'package:flutter/material.dart';
import '../../../services/prayer_service.dart';
import '../../../models/predefined_message.dart';
import '../../../l10n/app_localizations.dart';

class CreatePredefinedMessageModal extends StatefulWidget {
  const CreatePredefinedMessageModal({super.key});

  @override
  State<CreatePredefinedMessageModal> createState() => _CreatePredefinedMessageModalState();
}

class _CreatePredefinedMessageModalState extends State<CreatePredefinedMessageModal> {
  final PrayerService _prayerService = PrayerService();
  final TextEditingController _contentController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;
  List<PredefinedMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveMessage() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _prayerService.createPredefinedMessage(
        _contentController.text.trim(),
      );

      if (success && mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.messageSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorSavingMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${AppLocalizations.of(context)!.error}: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    try {
      final messages = await _prayerService.getPastorPredefinedMessages();
      if (mounted) {
        setState(() {
          _messages = messages;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorLoadingMessages(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.sureYouWantToDeleteThisMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    setState(() => _isLoading = true);
    try {
      await _prayerService.deletePredefinedMessage(messageId);
      await _loadMessages();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.messageDeletedSuccessfully),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppLocalizations.of(context)!.errorDeleting2(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Usar SingleChildScrollView para evitar overflow cuando aparece el teclado
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.predefinedMessage),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                )
              : TextButton.icon(
                  onPressed: _saveMessage,
                  icon: const Icon(Icons.save, color: Colors.white),
                  label: Text(
                    AppLocalizations.of(context)!.save,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 0,
                      color: Colors.blue.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)!.createMessageYouCanUseRepeatedly,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.blue[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    Text(
                      AppLocalizations.of(context)!.messageContent,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    TextFormField(
                      controller: _contentController,
                      maxLines: 8,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.writeHereThePredefinedMessageContent,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
                        ),
                        fillColor: Colors.grey[50],
                        filled: true,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return AppLocalizations.of(context)!.pleaseEnterMessageContent;
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      AppLocalizations.of(context)!.savedMessages,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _isLoading && _messages.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _messages.isEmpty
                        ? Card(
                          color: Colors.grey[100],
                          elevation: 0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Center(
                              child: Text(AppLocalizations.of(context)!.noPredefinedMessagesSavedYet),
                            ),
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final message = _messages[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              elevation: 1,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              child: ListTile(
                                title: Text(
                                  message.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  icon: Icon(Icons.delete_outline, color: Colors.red[700]),
                                  tooltip: AppLocalizations.of(context)!.deleteMessage,
                                  onPressed: () => _deleteMessage(message.id),
                                ),
                              ),
                            );
                          },
                        ),
                    
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[100]!),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red[700]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 