import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/cult.dart';
import '../../../models/time_slot.dart';
import '../modals/create_time_slot_modal.dart';
import '../time_slot_detail_screen.dart';
import '../../../theme/app_colors.dart';
import '../../../l10n/app_localizations.dart';

class CultTimeSlotsTab extends StatefulWidget {
  final Cult cult;
  
  const CultTimeSlotsTab({
    Key? key,
    required this.cult,
  }) : super(key: key);

  @override
  State<CultTimeSlotsTab> createState() => _CultTimeSlotsTabState();
}

class _CultTimeSlotsTabState extends State<CultTimeSlotsTab> {
  // bool _isPastor = false;
  // bool _isLoading = true;
  
  // Lista completa de horas (0-23)
  final List<int> _hoursList = List.generate(24, (index) => index);
  
  // Lista de colores para las franjas horarias
  final List<Color> _slotColors = [
    Colors.blue[400]!,
    Colors.purple[300]!,
    Colors.indigo[400]!,
    Colors.cyan[600]!,
    Colors.teal[400]!,
    Colors.green[500]!,
    Colors.amber[600]!,
    Colors.deepOrange[400]!,
  ];
  
  @override
  void initState() {
    super.initState();
    // _checkPastorStatus();
  }
  
  // Verifica se o usuário atual é um pastor
  /*
  Future<void> _checkPastorStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _isPastor = userData['role'] == 'pastor';
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erro ao verificar função de pastor: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  */

  void _showCreateTimeSlotModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateTimeSlotModal(cult: widget.cult),
    );
  }
  
  // Formata a hora para exibição
  String _formatHour(int hour) {
    if (hour == 0) return '12 AM';
    if (hour < 12) return '$hour AM';
    if (hour == 12) return '12 PM';
    return '${hour - 12} PM';
  }
  
  // Obtém uma cor com base no nome ou ID da faixa horária
  Color _getSlotColor(TimeSlot timeSlot) {
    // Se o timeSlot tem uma cor atribuída, usá-la
    // Como isso é uma demonstração, geramos uma cor baseada no hash do nome
    final colorIndex = timeSlot.name.hashCode.abs() % _slotColors.length;
    return _slotColors[colorIndex];
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('time_slots')
            .where('entityId', isEqualTo: widget.cult.id)
            .where('entityType', isEqualTo: 'cult')
            .where('isActive', isEqualTo: true)
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)));
          }
          
          List<TimeSlot> timeSlots = [];
          if (snapshot.hasData) {
            timeSlots = snapshot.data!.docs.map((doc) {
              try {
                return TimeSlot.fromFirestore(doc);
              } catch (e) {
                debugPrint('Erro ao converter documento: $e');
                return null;
              }
            }).where((timeSlot) => timeSlot != null).cast<TimeSlot>().toList();
          }
          
          return LayoutBuilder(
            builder: (context, constraints) {
              // Um único ScrollController que será compartilhado
              final ScrollController scrollController = ScrollController();
              
              return SingleChildScrollView(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                child: _buildCalendarView(timeSlots, constraints.maxWidth),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTimeSlotModal,
        tooltip: AppLocalizations.of(context)!.createTimeSlot,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
  
  // Constrói a visualização completa do calendário
  Widget _buildCalendarView(List<TimeSlot> timeSlots, double totalWidth) {
    // Largura para a coluna de horas
    const double hourColumnWidth = 65;
    // Largura disponível para as faixas
    final double contentWidth = totalWidth - hourColumnWidth;
    
    return Stack(
      children: [
        // Linhas da grade (horizontais)
        Column(
          children: List.generate(_hoursList.length, (index) {
            return Container(
              height: 60,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1, color: Colors.grey[300]!),
                ),
              ),
            );
          }),
        ),
        
        // Coluna de horas (esquerda)
        Column(
          children: _hoursList.map((hour) {
            return Container(
              height: 60,
              width: hourColumnWidth,
              padding: const EdgeInsets.only(left: 10, top: 10),
              child: Text(
                _formatHour(hour),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
        
        // Faixas horárias (sobre o conteúdo)
        Positioned(
          left: hourColumnWidth,
          child: Container(
            width: contentWidth,
            height: _hoursList.length * 60, // altura total
            child: _buildTimeSlotsOverlay(timeSlots, contentWidth),
          ),
        ),
      ],
    );
  }
  
  // Constrói a camada de faixas horárias
  Widget _buildTimeSlotsOverlay(List<TimeSlot> timeSlots, double availableWidth) {
    if (timeSlots.isEmpty) {
      return Container();
    }
    
    // Agrupar faixas por horas sobrepostas
    final Map<int, List<TimeSlot>> slotGroups = {};
    
    // Determinar os grupos de faixas que se sobrepõem
    for (var slot in timeSlots) {
      final groupId = slot.startTime.millisecondsSinceEpoch;
      bool foundGroup = false;
      
      for (var existingGroupId in slotGroups.keys) {
        final existingSlots = slotGroups[existingGroupId]!;
        bool overlaps = false;
        
        // Verificar se há sobreposição com alguma faixa do grupo
        for (var existingSlot in existingSlots) {
          if (_slotsOverlap(slot, existingSlot)) {
            overlaps = true;
            break;
          }
        }
        
        if (overlaps) {
          slotGroups[existingGroupId]!.add(slot);
          foundGroup = true;
          break;
        }
      }
      
      if (!foundGroup) {
        slotGroups[groupId] = [slot];
      }
    }
    
    // Construir as faixas como widgets posicionados
    final List<Widget> slotWidgets = [];
    
    slotGroups.forEach((groupId, groupSlots) {
      final slotWidth = (availableWidth - 8) / groupSlots.length;
      
      for (int i = 0; i < groupSlots.length; i++) {
        final slot = groupSlots[i];
        
        // Calcular a posição vertical (em pixels) com base na hora de início
        final double top = _calculateTopPosition(slot.startTime);
        
        // Calcular a altura com base na duração total
        final double height = _calculateTotalHeight(slot.startTime, slot.endTime);
        
        slotWidgets.add(
          Positioned(
            top: top,
            left: 4 + (i * slotWidth),
            width: slotWidth - 4, // Subtraímos 4 para a margem
            height: height,
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TimeSlotDetailScreen(
                      timeSlot: slot,
                      cult: widget.cult,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: _getSlotColor(slot),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      slot.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatTimeRange(slot.startTime, slot.endTime),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    });
    
    return Stack(children: slotWidgets);
  }
  
  // Calcula a posição vertical em pixels com base na hora de início
  double _calculateTopPosition(DateTime time) {
    return (time.hour * 60) + (time.minute * 1.0); // cada hora = 60px, cada minuto = 1px
  }
  
  // Calcula a altura total em pixels com base na duração
  double _calculateTotalHeight(DateTime start, DateTime end) {
    // Diferença em minutos
    final diffMinutes = end.difference(start).inMinutes;
    // Converter minutos em altura de pixels (1 minuto = 1px)
    return diffMinutes.toDouble();
  }
  
  // Verifica se duas faixas horárias se sobrepõem no tempo
  bool _slotsOverlap(TimeSlot slot1, TimeSlot slot2) {
    return (slot1.startTime.isBefore(slot2.endTime) && 
            slot1.endTime.isAfter(slot2.startTime));
  }
  
  // Formata o intervalo de horas para exibição na faixa
  String _formatTimeRange(DateTime start, DateTime end) {
    String formatHour(DateTime time) {
      final hour = time.hour;
      final minute = time.minute;
      
      String hourStr;
      if (hour == 0) hourStr = '12';
      else if (hour < 12) hourStr = '$hour';
      else if (hour == 12) hourStr = '12';
      else hourStr = '${hour - 12}';
      
      String amPm = hour < 12 ? 'am' : 'pm';
      
      // Solo mostrar minutos cuando no son cero
      if (minute > 0) {
        return '$hourStr:${minute.toString().padLeft(2, '0')}$amPm';
      } else {
        return '$hourStr$amPm';
      }
    }
    
    return '${formatHour(start)} – ${formatHour(end)}';
  }
}