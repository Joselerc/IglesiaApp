import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../models/cult.dart';
import '../../../services/work_schedule_service.dart';
import '../../../theme/app_colors.dart';

class DuplicateSimpleModal extends StatefulWidget {
  final Cult cult;
  
  const DuplicateSimpleModal({
    Key? key,
    required this.cult,
  }) : super(key: key);

  @override
  State<DuplicateSimpleModal> createState() => _DuplicateSimpleModalState();
}

class _DuplicateSimpleModalState extends State<DuplicateSimpleModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final List<DateTime> _selectedDates = [];
  bool _isLoading = false;
  
  // Opções de duplicação
  bool _duplicateAnnouncements = true;
  bool _duplicateSongs = true;
  bool _duplicateTimeSlots = true;
  bool _duplicateMinistries = true;
  bool _duplicateUsers = true;
  
  // Configuração de anúncios
  int _announcementDaysInAdvance = 7; // Por padrão, 7 dias antes
  
  // Verificação de elementos existentes
  bool _cultHasAnnouncements = false;
  bool _cultHasSongs = false;
  bool _cultHasTimeSlots = false;
  
  @override
  void initState() {
    super.initState();
    
    // Inicializar com valores do culto original
    _nameController.text = '${widget.cult.name} (cópia)';
    
    // Verificar quais elementos tem o culto original
    _checkCultElements();
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  Future<void> _addDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDates.add(picked);
      });
    }
  }
  
  void _removeDate(int index) {
    setState(() {
      _selectedDates.removeAt(index);
    });
  }
  
  // Verificar quais elementos tem o culto original
  Future<void> _checkCultElements() async {
    try {
      // Verificar se tem anúncios
      final announcementsSnapshot = await FirebaseFirestore.instance
          .collection('announcements')
          .where('cultId', isEqualTo: widget.cult.id)
          .where('type', isEqualTo: 'cult')
          .limit(1)
          .get();
      
      // Verificar se tem músicas
      final songsSnapshot = await FirebaseFirestore.instance
          .collection('cult_songs')
          .where('cultId', isEqualTo: widget.cult.id)
          .limit(1)
          .get();
      
      // Verificar se tem faixas horárias
      final timeSlotsSnapshot = await FirebaseFirestore.instance
          .collection('time_slots')
          .where('entityId', isEqualTo: widget.cult.id)
          .where('entityType', isEqualTo: 'cult')
          .limit(1)
          .get();
      
      if (mounted) {
        setState(() {
          _cultHasAnnouncements = announcementsSnapshot.docs.isNotEmpty;
          _cultHasSongs = songsSnapshot.docs.isNotEmpty;
          _cultHasTimeSlots = timeSlotsSnapshot.docs.isNotEmpty;
          
          print('Culto tem anúncios: $_cultHasAnnouncements');
          print('Culto tem músicas: $_cultHasSongs');
          print('Culto tem faixas horárias: $_cultHasTimeSlots');
          
          // Atualizar opções de acordo com o que existe
          _duplicateAnnouncements = _cultHasAnnouncements;
          _duplicateSongs = _cultHasSongs;
          _duplicateTimeSlots = _cultHasTimeSlots;
          
          // Se não há faixas horárias, desativar opções dependentes
          if (!_cultHasTimeSlots) {
            _duplicateMinistries = false;
            _duplicateUsers = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar elementos do culto: $e');
    }
  }
  
  Future<void> _duplicateCult() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    if (_selectedDates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Selecione pelo menos uma data para duplicar o culto'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      for (final date in _selectedDates) {
        debugPrint('Duplicando culto para data: $date');
        debugPrint('ID do serviço original: ${widget.cult.serviceId}');
        
        // Criar novo culto
        final cultDate = DateTime(
          date.year,
          date.month,
          date.day,
        );
        
        // Usar a hora original ou permitir configurar nova hora
        final startTime = DateTime(
          date.year,
          date.month,
          date.day,
          widget.cult.startTime.hour,
          widget.cult.startTime.minute,
        );
        
        // Calcular a duração do culto original
        final originalDuration = widget.cult.endTime.difference(widget.cult.startTime);
        
        // Calcular a hora de fim somando a duração
        final endTime = startTime.add(originalDuration);
        
        // Criar o novo culto
        final newCultData = {
          'serviceId': FirebaseFirestore.instance.collection('services').doc(widget.cult.serviceId),
          'name': _nameController.text,
          'date': Timestamp.fromDate(cultDate),
          'startTime': Timestamp.fromDate(startTime),
          'endTime': Timestamp.fromDate(endTime),
          'status': 'planejado',
          'createdBy': widget.cult.createdBy,
          'createdAt': Timestamp.now(),
        };
        
        debugPrint('Dados do novo culto: $newCultData');
        final newCultRef = await FirebaseFirestore.instance.collection('cults').add(newCultData);
        debugPrint('Novo culto criado com ID: ${newCultRef.id}');
        
        // Configurar opções de duplicação
        Map<String, bool> duplicateOptions = {
          'duplicateAnnouncements': _duplicateAnnouncements,
          'duplicateSongs': _duplicateSongs,
          'duplicateTimeSlots': _duplicateTimeSlots,
          'duplicateMinistries': _duplicateMinistries,
          'duplicateUsers': _duplicateUsers,
        };
        
        // Adicionar configuração adicional
        Map<String, dynamic> additionalOptions = {
          'announcementDaysInAdvance': _announcementDaysInAdvance,
        };
        
        // Duplicar faixas horárias e atribuições conforme opções
        await WorkScheduleService().duplicateCult(
          sourceCultId: widget.cult.id,
          newCultId: newCultRef.id,
          newCultDate: cultDate,
          options: duplicateOptions,
          additionalOptions: additionalOptions,
        );
      }
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_selectedDates.length} culto(s) duplicado(s) com sucesso'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao duplicar culto: $e'),
            backgroundColor: AppColors.error,
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
    final dateFormat = DateFormat('EEEE, dd MMMM yyyy', 'pt_BR');
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          resizeToAvoidBottomInset: false,
          body: Form(
            key: _formKey,
            child: Column(
              children: [
                // AppBar personalizado
                Container(
                  padding: const EdgeInsets.all(16.0),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Text(
                        'Duplicação Simples',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                
                // Conteúdo rolável
                Expanded(
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome do culto
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nome do culto',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.church),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Por favor, insira um nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Datas selecionadas
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Datas selecionadas',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _addDate,
                              icon: const Icon(Icons.add),
                              label: const Text('Adicionar data'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                textStyle: const TextStyle(fontSize: 13),
                                iconColor: Colors.white,
                                elevation: 2,
                              ),
                            ),
                          ],
                        ),
                        
                        if (_selectedDates.isEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.orange.shade800),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Selecione pelo menos uma data para duplicar o culto',
                                    style: TextStyle(color: Colors.deepOrange),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedDates.length,
                            itemBuilder: (context, index) {
                              return Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ListTile(
                                  leading: Icon(Icons.event, color: AppColors.primary),
                                  title: Text(
                                    dateFormat.format(_selectedDates[index]),
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.delete, color: AppColors.error),
                                    onPressed: () => _removeDate(index),
                                  ),
                                ),
                              );
                            },
                          ),
                        
                        const SizedBox(height: 24),
                        
                        // Elementos a duplicar
                        const Text(
                          'Elementos a duplicar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        CheckboxListTile(
                          value: _duplicateAnnouncements,
                          onChanged: _cultHasAnnouncements ? (value) {
                            setState(() {
                              _duplicateAnnouncements = value ?? true;
                            });
                          } : null,
                          title: const Text('Anúncios'),
                          subtitle: const Text('Serão duplicados os anúncios do culto'),
                          secondary: const Icon(Icons.announcement),
                          activeColor: AppColors.primary,
                        ),
                        
                        // Config dias de antecedência de anúncios (só visível se duplicateAnnouncements estiver ativo)
                        if (_duplicateAnnouncements && _cultHasAnnouncements)
                          Padding(
                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 8.0),
                            child: Row(
                              children: [
                                const Expanded(
                                  flex: 3,
                                  child: Text('Dias de antecedência para mostrar anúncios:'),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 1,
                                  child: TextFormField(
                                    initialValue: _announcementDaysInAdvance.toString(),
                                    decoration: const InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Necessário';
                                      }
                                      final intValue = int.tryParse(value);
                                      if (intValue == null || intValue <= 0) {
                                        return 'Inválido';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      final intValue = int.tryParse(value);
                                      if (intValue != null && intValue > 0) {
                                        setState(() {
                                          _announcementDaysInAdvance = intValue;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        CheckboxListTile(
                          value: _duplicateSongs,
                          onChanged: _cultHasSongs ? (value) {
                            setState(() {
                              _duplicateSongs = value ?? true;
                            });
                          } : null,
                          title: const Text('Músicas'),
                          subtitle: const Text('Serão duplicadas as músicas do culto'),
                          secondary: const Icon(Icons.music_note),
                          activeColor: AppColors.primary,
                        ),
                        
                        CheckboxListTile(
                          value: _duplicateTimeSlots,
                          onChanged: _cultHasTimeSlots ? (value) {
                            setState(() {
                              _duplicateTimeSlots = value ?? true;
                              // Se desmarca faixas, desmarcar o que depende
                              if (!_duplicateTimeSlots) {
                                _duplicateMinistries = false;
                                _duplicateUsers = false;
                              }
                            });
                          } : null,
                          title: const Text('Faixas Horárias'),
                          subtitle: const Text('Divisões de tempo dentro do culto'),
                          secondary: const Icon(Icons.timeline),
                          activeColor: AppColors.primary,
                        ),
                        
                        CheckboxListTile(
                          value: _duplicateMinistries,
                          onChanged: (_cultHasTimeSlots && _duplicateTimeSlots) ? (value) {
                            setState(() {
                              _duplicateMinistries = value ?? true;
                              // Se desmarca ministérios, desmarcar usuários
                              if (!_duplicateMinistries) {
                                _duplicateUsers = false;
                              }
                            });
                          } : null,
                          title: const Text('Ministérios'),
                          subtitle: const Text('Atribuições de ministérios a faixas horárias'),
                          secondary: const Icon(Icons.people_alt),
                          activeColor: AppColors.primary,
                        ),
                        
                        CheckboxListTile(
                          value: _duplicateUsers,
                          onChanged: (_cultHasTimeSlots && _duplicateTimeSlots && _duplicateMinistries) ? (value) {
                            setState(() {
                              _duplicateUsers = value ?? true;
                            });
                          } : null,
                          title: const Text('Usuários Convidados'),
                          subtitle: const Text('Serão enviados convites para as mesmas pessoas'),
                          secondary: const Icon(Icons.person_add),
                          activeColor: AppColors.primary,
                        ),
                        
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
                
                // Botão de ação na parte inferior
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _duplicateCult,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      disabledBackgroundColor: Colors.grey[400],
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Duplicar Culto',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 