import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../../models/cult.dart';
import '../../../models/prayer.dart';
import '../../../services/prayer_service.dart';
import '../../../l10n/app_localizations.dart';

class AssignCultModal extends StatefulWidget {
  final Prayer prayer;

  const AssignCultModal({super.key, required this.prayer});

  @override
  State<AssignCultModal> createState() => _AssignCultModalState();
}

class _AssignCultModalState extends State<AssignCultModal> {
  final PrayerService _prayerService = PrayerService();
  
  List<Cult> _cults = [];
  bool _isLoading = true;
  bool _isSaving = false;
  String _searchText = '';
  Cult? _selectedCult;
  
  @override
  void initState() {
    super.initState();
    _loadCults();
  }
  
  Future<void> _loadCults() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final cults = await _prayerService.getFutureCults();
      
      setState(() {
        _cults = cults;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar cultos: $e');
      
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorLoadingCults(e.toString()))),
        );
      }
    }
  }

  Future<void> _assignPrayer() async {
    if (_selectedCult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.pleaseSelectACult)),
      );
      return;
    }
    
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.youMustBeLoggedInToAssignPrayers)),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      final success = await _prayerService.assignPrayerToCult(
        prayerId: widget.prayer.id,
        cultId: _selectedCult!.id,
        cultName: _selectedCult!.name,
        pastorId: currentUser.uid,
      );
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.prayerAssignedSuccessfullyToCult(_selectedCult!.name))),
        );
        Navigator.pop(context, true); // Retornar true indica éxito
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorAssigningPrayerToCult)),
        );
      }
    } catch (e) {
      print('Error al asignar oración: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorAssigningPrayer(e.toString()))),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
  
  List<Cult> get _filteredCults {
    if (_searchText.isEmpty) {
      return _cults;
    }
    
    return _cults.where((cult) => 
      cult.name.toLowerCase().contains(_searchText.toLowerCase()) ||
      DateFormat('dd/MM/yyyy').format(cult.date).contains(_searchText)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barra superior con título y botón de cerrar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Asignar a Culto',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Contenido de la oración
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Oración a asignar:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.prayer.content,
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Buscador de cultos
          TextField(
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchCultByNameOrDate,
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onChanged: (value) {
              setState(() {
                _searchText = value;
              });
            },
          ),
          
          const SizedBox(height: 16),
          
          // Lista de cultos
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredCults.isEmpty
                ? Center(
                    child: Text(
                      _searchText.isEmpty 
                        ? 'No hay cultos próximos disponibles' 
                        : 'No se encontraron cultos con "$_searchText"',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    itemCount: _filteredCults.length,
                    itemBuilder: (context, index) {
                      final cult = _filteredCults[index];
                      final isSelected = _selectedCult?.id == cult.id;
                      
                      return Card(
                        elevation: isSelected ? 2 : 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: isSelected ? theme.primaryColor : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () {
                            setState(() {
                              _selectedCult = isSelected ? null : cult;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
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
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(
                                        Icons.check_circle,
                                        color: theme.primaryColor,
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('EEEE, d MMM yyyy', 'es').format(cult.date),
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${DateFormat('HH:mm').format(cult.startTime)} - ${DateFormat('HH:mm').format(cult.endTime)}',
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // Botón para asignar
          ElevatedButton(
            onPressed: _isSaving || _selectedCult == null ? null : _assignPrayer,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'ASIGNAR ORACIÓN',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
} 