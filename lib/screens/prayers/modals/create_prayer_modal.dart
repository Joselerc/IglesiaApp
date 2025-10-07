import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_text_styles.dart';
import '../../../l10n/app_localizations.dart';

class CreatePrayerModal extends StatefulWidget {
  const CreatePrayerModal({super.key});

  @override
  State<CreatePrayerModal> createState() => _CreatePrayerModalState();
}

class _CreatePrayerModalState extends State<CreatePrayerModal> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  bool _isAnonymous = false;
  bool _isLoading = false;
  int get _remainingChars => 200 - (_contentController.text.length);

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submitPrayer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.youMustBeLoggedInToSendPrayer)),
          );
        }
        return;
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      
      await FirebaseFirestore.instance.collection('prayers').add({
        'content': _contentController.text.trim(),
        'createdBy': userRef,
        'createdAt': FieldValue.serverTimestamp(),
        'isAnonymous': _isAnonymous,
        'isAccepted': false,
        'upVotedBy': [],
        'downVotedBy': [],
        'score': 0,
        'totalVotes': 0,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.prayerSentSuccessfully),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.errorSendingPrayer(e.toString())),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
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

  @override
  Widget build(BuildContext context) {
    // Obtener los paddings del sistema (teclado y área segura)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Aplicar padding que incluye espacio para teclado y área segura
      padding: EdgeInsets.fromLTRB(
        20, 
        16, 
        20, 
        // Asegurar al menos un padding base (ej: 20) + el espacio del teclado + el padding del sistema
        20 + bottomInset + bottomPadding 
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra superior con título y botón de cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)!.prayerRequest,
                    style: AppTextStyles.headline3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Información explicativa
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.primary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.yourPrayerWillBeSharedWithCommunity,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Campo para el contenido de la oración
              TextFormField(
                controller: _contentController,
                maxLength: 200,
                maxLines: 5,
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.whyDoYouNeedPrayer,
                  hintStyle: TextStyle(color: AppColors.textSecondary.withOpacity(0.7)),
                  filled: true,
                  fillColor: Colors.grey[50],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary, width: 2),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                  counterText: '',
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() {}), // Actualizar contador de caracteres
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return AppLocalizations.of(context)!.pleaseWriteYourPrayerRequest;
                  }
                  return null;
                },
              ),
              
              // Contador de caracteres restantes
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    AppLocalizations.of(context)!.charactersRemaining(_remainingChars),
                    style: TextStyle(
                      fontSize: 12,
                      color: _remainingChars < 20 ? Colors.red : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Opción para publicar anónimamente
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.publishAnonymously,
                            style: AppTextStyles.subtitle2.copyWith(
                              fontWeight: FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            AppLocalizations.of(context)!.yourNameWillRemainHidden,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAnonymous,
                      onChanged: (value) => setState(() => _isAnonymous = value),
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Botón de enviar
              ElevatedButton(
                onPressed: _isLoading ? null : _submitPrayer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.publishRequest.toUpperCase(),
                        style: AppTextStyles.button.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}