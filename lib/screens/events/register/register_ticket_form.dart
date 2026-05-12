import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/event_model.dart';
import '../../../models/ticket_model.dart';
import '../../../services/ticket_service.dart';
import 'qr_fullscreen_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterTicketForm extends StatefulWidget {
  final EventModel event;
  final String ticketId;

  const RegisterTicketForm({
    Key? key,
    required this.event,
    required this.ticketId,
  }) : super(key: key);

  @override
  _RegisterTicketFormState createState() => _RegisterTicketFormState();
}

class _RegisterTicketFormState extends State<RegisterTicketForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _fieldControllers = {};

  final _ticketService = TicketService();
  bool _isLoading = false;
  String? _errorMessage;
  TicketModel? _ticket;
  Map<String, dynamic> _userData = {};

  AppLocalizations get _loc => AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadTicketData();
  }

  @override
  void dispose() {
    // Limpar todos os controladores
    _fieldControllers.forEach((_, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _userData = {
          'displayName': user.displayName ?? '',
          'email': user.email ?? '',
          'phoneNumber':
              user.phoneNumber ?? '', // Campo padrão do Firebase Auth
          'photoURL': user.photoURL,
          'uid': user.uid,
        };
      });

      // Tentar carregar dados adicionais do usuário do Firestore
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final additionalData = userDoc.data() as Map<String, dynamic>;
          // Garantir que não sobrescreva campos essenciais com nulos ou vazios
          additionalData.forEach((key, value) {
            if (value != null && (value is String ? value.isNotEmpty : true)) {
              _userData[key] = value;
            }
          });
          setState(() {}); // Atualizar estado após mesclar dados
        }
      } catch (e) {
        print('Erro ao carregar dados adicionais do usuário: $e');
      }
    }
  }

  Future<void> _loadTicketData() async {
    setState(() => _isLoading = true);

    try {
      final ticket =
          await _ticketService.getTicketById(widget.event.id, widget.ticketId);

      if (ticket == null) {
        setState(() {
          _errorMessage = _loc.ticketLoadError;
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _ticket = ticket;

        // Criar controladores para os campos personalizados
        for (final field in ticket.formFields) {
          final controller = TextEditingController();

          // Log 1: Início do processamento do campo
          print('--- Campo: ${field.id} (${field.label}) ---');
          print(
              '  useUserProfile: ${field.useUserProfile}, userProfileField: ${field.userProfileField}');

          // Lógica de preenchimento aprimorada
          if (field.useUserProfile && field.userProfileField.isNotEmpty) {
            final profileFieldKey = field.userProfileField; // Campo primário configurado
            String? valueToFill;
            bool isPhoneField = field.type == 'phone';

            // Log 2: Tentando usar perfil
            print('  Tentando preencher com chave de perfil: $profileFieldKey');

            // Buscar valor inicial e logar
            dynamic
                rawValueFromProfile; // Usar dynamic para logar o tipo original
            if (_userData.containsKey(profileFieldKey)) {
              rawValueFromProfile = _userData[profileFieldKey];
              // Log 3: Valor encontrado (cru)
              print(
                  '  Valor encontrado para $profileFieldKey em _userData: $rawValueFromProfile (Tipo: ${rawValueFromProfile?.runtimeType})');
              if (rawValueFromProfile != null &&
                  rawValueFromProfile.toString().trim().isNotEmpty) {
                valueToFill = rawValueFromProfile.toString();
              }
            } else {
              // Log 3: Chave não encontrada
              print('  Chave $profileFieldKey NÃO encontrada em _userData');
            }

            // Lógica de Fallback APENAS para telefone (mantendo logs existentes)
            if (isPhoneField) {
              // 1. Tentar phoneComplete primeiro (se não for o campo primário já buscado)
              const phoneCompleteKey = 'phoneComplete';
              if (profileFieldKey != phoneCompleteKey &&
                  _userData.containsKey(phoneCompleteKey)) {
                final phoneCompValue = _userData[phoneCompleteKey];
                if (phoneCompValue != null &&
                    phoneCompValue.toString().trim().isNotEmpty) {
                  valueToFill = phoneCompValue
                      .toString(); // Sobrescreve se phoneComplete tiver valor
                  print(
                      '  [Telefone] Usando phoneComplete (${valueToFill}) diretamente.');
                }
              }

              // 2. Se AINDA vazio, verificar campo primário e adicionar prefixo se necessário
              if ((valueToFill == null || valueToFill.isEmpty) &&
                  rawValueFromProfile != null &&
                  rawValueFromProfile.toString().trim().isNotEmpty) {
                valueToFill = rawValueFromProfile
                    .toString(); // Usar o valor primário encontrado
                if (!valueToFill.startsWith('+')) {
                  if (!valueToFill.startsWith('55')) {
                    valueToFill = '+55' + valueToFill;
                    print(
                        '  [Telefone] Adicionando +55 ao valor de ${profileFieldKey} (${rawValueFromProfile}). Resultado: ${valueToFill}');
                  } else if (valueToFill.length > 9) {
                    // Evitar adicionar +5555...
                    valueToFill = '+' + valueToFill;
                    print(
                        '  [Telefone] Adicionando + ao valor de ${profileFieldKey} (${rawValueFromProfile}). Resultado: ${valueToFill}');
                  }
                }
              }

              // 3. Se AINDA vazio, tentar fallback para 'phone' (se não for o primário) e adicionar prefixo
              const phoneKey = 'phone';
              if ((valueToFill == null || valueToFill.isEmpty) &&
                  profileFieldKey != phoneKey &&
                  _userData.containsKey(phoneKey)) {
                final phoneValue = _userData[phoneKey];
                if (phoneValue != null &&
                    phoneValue.toString().trim().isNotEmpty) {
                  valueToFill = phoneValue.toString();
                  if (!valueToFill.startsWith('+')) {
                    if (!valueToFill.startsWith('55')) {
                      valueToFill = '+55' + valueToFill;
                      print(
                          '  [Telefone Fallback] Usando ${phoneKey} e adicionando +55. Resultado: ${valueToFill}');
                    } else if (valueToFill.length > 9) {
                      valueToFill = '+' + valueToFill;
                      print(
                          '  [Telefone Fallback] Usando ${phoneKey} e adicionando +. Resultado: ${valueToFill}');
                    }
                  }
                }
              }
            }
            // Fim da lógica específica de telefone

            // Atribuição final ao controller
            controller.text = valueToFill ?? '';

            // Log 5: Valor final atribuído
            print(
                '  => Final atribuído ao campo ${field.id}: "${controller.text}"');
          } else {
            // Log 2: Não vai usar perfil
            print(
                '  Não usará perfil (useUserProfile=${field.useUserProfile}, userProfileField=${field.userProfileField})');
            controller.text = '';
            print(
                '  => Final atribuído ao campo ${field.id}: "${controller.text}"');
          }

          _fieldControllers[field.id] = controller;
        }
      });
    } catch (e) {
      setState(() {
        _errorMessage = '${_loc.ticketLoadError}: ${e.toString()}';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registerForTicket() async {
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    if (_ticket == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_loc.ticketLoadError)),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Coletar dados de todos os campos
      final Map<String, dynamic> formData = {};
      _fieldControllers.forEach((fieldId, controller) {
        formData[fieldId] = controller.text.trim();
      });

      // Garantir que o nome do evento não seja nulo
      final String safeEventName = (widget.event.title.isNotEmpty)
          ? widget.event.title
          : _loc.eventFallbackName;

      // Extrair valores básicos (assumindo IDs 'fullName', 'email', 'phone')
      // Se os IDs forem diferentes, ajuste aqui.
      final userName = _fieldControllers['fullName']?.text.trim() ??
          _userData['displayName'] ??
          '';
      final userEmail =
          _fieldControllers['email']?.text.trim() ?? _userData['email'] ?? '';
      final userPhone = _fieldControllers['phone']?.text.trim() ??
          _userData['phoneNumber'] ??
          _userData['phone'] ??
          '';

      // Registrar para o ingresso
      await _ticketService.registerForTicket(
        ticketId: widget.ticketId,
        eventId: widget.event.id,
        eventName: safeEventName,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        formData: formData,
      );

      // Obter o registro recém-criado
      final registration =
          await _ticketService.getMyRegistrationForEvent(widget.event.id);

      if (registration != null && mounted) {
        // Fechar o formulário atual
        Navigator.of(context)
            .pop(true); // Passar true para indicar que o registro foi concluído

        // Mostrar o QR em tela cheia
        final String safeQrCode = registration.qrCode;
        final String safeUserName =
            userName.isNotEmpty ? userName : 'Participante'; // Traducido

        Navigator.of(context).push(
          MaterialPageRoute(
            fullscreenDialog: true,
            builder: (context) => QRFullscreenDialog(
              qrCode: safeQrCode,
              eventName: safeEventName,
              ticketType: _ticket!.type,
              userName: safeUserName,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage =
            e.toString(); // Manter erro técnico em inglês ou formatar
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildFormField(TicketFormField field) {
    final controller = _fieldControllers[field.id];
    final loc = _loc;
    if (controller == null) return SizedBox.shrink();

    // Determinar o tipo de teclado
    TextInputType keyboardType;
    switch (field.type) {
      case 'email':
        keyboardType = TextInputType.emailAddress;
        break;
      case 'phone':
        keyboardType = TextInputType.phone;
        break;
      case 'number':
        keyboardType = TextInputType.number;
        break;
      default:
        keyboardType = TextInputType.text;
    }

    // Função de validação conforme o tipo
    String? Function(String?)? validator;
    if (field.isRequired) {
      validator = (value) {
        if (value == null || value.trim().isEmpty) {
          return loc.requiredField;
        }

        if (field.type == 'email' && !value.contains('@')) {
          return loc.invalidEmail;
        }

        if (field.type == 'phone' &&
            value.replaceAll(RegExp(r'\D'), '').length < 8) {
          return loc.enterAValidPhoneNumber;
        }

        return null;
      };
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText:
              field.label, // Label já vem do Firestore (assumindo português)
          border: OutlineInputBorder(),
          prefixIcon: _getIconForFieldType(field.type),
        ),
        keyboardType: keyboardType,
        validator: validator,
        enabled: !_isLoading,
      ),
    );
  }

  // Ícones (manter em inglês, são identificadores)
  Widget? _getIconForFieldType(String type) {
    switch (type) {
      case 'text':
        return Icon(Icons.text_fields);
      case 'email':
        return Icon(Icons.email);
      case 'phone':
        return Icon(Icons.phone);
      case 'number':
        return Icon(Icons.pin); // Usar pin para número genérico?
      case 'select': // Assumindo que 'select' existe
        return Icon(Icons.arrow_drop_down_circle_outlined);
      default:
        return null; // Ou um ícone genérico como Icons.notes
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = _loc;
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.registerTicketFormTitle),
      ),
      body: _isLoading && _ticket == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(loc.loadingTicketInformation),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informações do ingresso
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.ticketInformationHeader,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Text('${loc.eventLabel}:'),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.event
                                        .title, // Já deve estar em português
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text('${loc.ticketTypeLabel}:'),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _ticket?.type ??
                                        '', // Já deve estar em português
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Row(
                              children: [
                                Text('${loc.ticketPriceLabel}:'),
                                SizedBox(width: 8),
                                Text(
                                  _ticket == null ? '' : _ticket!.priceDisplay(loc),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    Text(
                      loc.contactInformationHeader,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: 16),

                    // Campos de formulário dinâmicos
                    if (_ticket != null)
                      ..._ticket!.formFields
                          .map((field) => _buildFormField(field))
                          .toList(),

                    // Mensagem de erro
                    if (_errorMessage != null) ...[
                      SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage!, // Manter técnico ou traduzir dependendo do caso
                                style: TextStyle(color: Colors.red.shade800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    SizedBox(height: 24),

                    // Botão de registro
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _registerForTicket,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(loc.registerTicketButtonLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
