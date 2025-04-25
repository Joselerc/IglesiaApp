import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/prayer.dart';
import 'widgets/prayer_card.dart';
import '../prayers/modals/create_prayer_modal.dart';
import '../../widgets/empty_state.dart';
import '../../services/prayer_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class PublicPrayerScreen extends StatefulWidget {
  const PublicPrayerScreen({super.key});

  @override
  State<PublicPrayerScreen> createState() => _PublicPrayerScreenState();
}

class _PublicPrayerScreenState extends State<PublicPrayerScreen> {
  final ScrollController _scrollController = ScrollController();
  final PrayerService _prayerService = PrayerService();
  
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastVisibleDocument;
  String _sortBy = 'popular'; // 'recent', 'popular'
  String _filterBy = 'all'; // 'all', 'assigned'
  bool _isPastor = false;
  int _refreshKey = 0; // Añadir clave para forzar reconstrucción

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _checkIfUserIsPastor();
  }
  
  Future<void> _checkIfUserIsPastor() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    final isPastor = await _prayerService.isPastor(user.uid);
    if (mounted) {
      setState(() {
        _isPastor = isPastor;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !_isLoadingMore) {
      _loadMorePrayers();
    }
  }

  Future<void> _loadMorePrayers() async {
    if (_lastVisibleDocument == null || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      // Crear consulta base
      Query query = FirebaseFirestore.instance.collection('prayers');
      
      // Aplicar filtro según la selección
      if (_filterBy == 'assigned') {
        query = query.where('cultRef', isNull: false);
      }
      
      // Aplicar ordenamiento según la selección
      if (_sortBy == 'popular') {
        query = query.orderBy('score', descending: true)
                     .orderBy('createdAt', descending: true);
      } else {
        query = query.orderBy('createdAt', descending: true);
      }
      
      // Iniciar después del último documento visible
      query = query.startAfterDocument(_lastVisibleDocument!).limit(10);
      
      // Ejecutar consulta
      final snapshot = await query.get();
      
      if (snapshot.docs.isNotEmpty) {
        _lastVisibleDocument = snapshot.docs.last;
      }
    } catch (e) {
      debugPrint('Error al cargar más oraciones: $e');
      if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error al cargar más: ${e.toString()}')),
         );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  void _changeSort(String sortType) {
    if (_sortBy != sortType) {
      setState(() {
        _sortBy = sortType;
        _lastVisibleDocument = null;
      });
    }
  }
  
  void _changeFilter(String filterType) {
    if (_filterBy != filterType) {
      setState(() {
        _filterBy = filterType;
        _lastVisibleDocument = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Encabezado fijo con diseño gradiente y título
          Container(
            decoration: BoxDecoration(
              color: AppColors.primary,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.primary.withOpacity(0.7),
                  AppColors.primary,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 5,
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Barra superior con título y acciones
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text(
                          'Orações Públicas',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.sort, color: Colors.white),
                          tooltip: 'Ordenar por',
                          onSelected: _changeSort,
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'recent',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: _sortBy == 'recent' ? AppColors.primary : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mais recentes',
                                    style: TextStyle(
                                      color: _sortBy == 'recent' ? AppColors.primary : null,
                                      fontWeight: _sortBy == 'recent' ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'popular',
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.trending_up,
                                    color: _sortBy == 'popular' ? AppColors.primary : Colors.grey,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mais votadas',
                                    style: TextStyle(
                                      color: _sortBy == 'popular' ? AppColors.primary : null,
                                      fontWeight: _sortBy == 'popular' ? FontWeight.bold : null,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Chips de filtro con diseño mejorado
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filtrar por:',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filtros de ordenación
                      FilterChip(
                        label: const Text('Recentes'),
                        selected: _sortBy == 'recent',
                        onSelected: (_) => _changeSort('recent'),
                        avatar: Icon(
                          Icons.access_time,
                          size: 18,
                          color: _sortBy == 'recent' ? AppColors.primary : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: _sortBy == 'recent' ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: _sortBy == 'recent' ? FontWeight.bold : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _sortBy == 'recent' ? AppColors.primary.withOpacity(0.5) : Colors.grey[300]!,
                            width: _sortBy == 'recent' ? 1.5 : 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Mais votadas'),
                        selected: _sortBy == 'popular',
                        onSelected: (_) => _changeSort('popular'),
                        avatar: Icon(
                          Icons.trending_up,
                          size: 18,
                          color: _sortBy == 'popular' ? AppColors.primary : AppColors.textSecondary,
                        ),
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: _sortBy == 'popular' ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: _sortBy == 'popular' ? FontWeight.bold : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: _sortBy == 'popular' ? AppColors.primary.withOpacity(0.5) : Colors.grey[300]!,
                            width: _sortBy == 'popular' ? 1.5 : 1.0,
                          ),
                        ),
                      ),
                      
                      // Filtros de pastor para asignación a cultos
                      if (_isPastor) ...[
                        const SizedBox(width: 12),
                        const SizedBox(
                          height: 24,
                          child: VerticalDivider(thickness: 1),
                        ),
                        const SizedBox(width: 12),
                        FilterChip(
                          label: const Text('Todas'),
                          selected: _filterBy == 'all',
                          onSelected: (_) => _changeFilter('all'),
                          avatar: Icon(
                            Icons.list,
                            size: 18,
                            color: _filterBy == 'all' ? Colors.blue : AppColors.textSecondary,
                          ),
                          selectedColor: Colors.blue.withOpacity(0.15),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: _filterBy == 'all' ? Colors.blue : AppColors.textPrimary,
                            fontWeight: _filterBy == 'all' ? FontWeight.bold : FontWeight.normal,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _filterBy == 'all' ? Colors.blue.withOpacity(0.5) : Colors.grey[300]!,
                              width: _filterBy == 'all' ? 1.5 : 1.0,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Atribuídas'),
                          selected: _filterBy == 'assigned',
                          onSelected: (_) => _changeFilter('assigned'),
                          avatar: Icon(
                            Icons.church,
                            size: 18,
                            color: _filterBy == 'assigned' ? Colors.blue : AppColors.textSecondary,
                          ),
                          selectedColor: Colors.blue.withOpacity(0.15),
                          showCheckmark: false,
                          labelStyle: TextStyle(
                            color: _filterBy == 'assigned' ? Colors.blue : AppColors.textPrimary,
                            fontWeight: _filterBy == 'assigned' ? FontWeight.bold : FontWeight.normal,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: _filterBy == 'assigned' ? Colors.blue.withOpacity(0.5) : Colors.grey[300]!,
                              width: _filterBy == 'assigned' ? 1.5 : 1.0,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de oraciones
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              key: ValueKey('$_sortBy-$_filterBy-$_refreshKey'),
              stream: _buildPrayersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  debugPrint('Error en StreamBuilder: ${snapshot.error}');
                  return Center(
                    child: Text('Error al cargar oraciones: ${snapshot.error}'),
                  );
                }
                
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEnhancedEmptyState();
                }
                
                final prayers = snapshot.data!.docs
                    .map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      // Handle missing score field for older documents
                      if (data['score'] == null) {
                        final upVotedByLength = (data['upVotedBy'] as List?)?.length ?? 0;
                        final downVotedByLength = (data['downVotedBy'] as List?)?.length ?? 0;
                        data['score'] = upVotedByLength - downVotedByLength;
                      }
                      
                      // Handle missing totalVotes field for older documents
                      if (data['totalVotes'] == null) {
                        final upVotedByLength = (data['upVotedBy'] as List?)?.length ?? 0;
                        final downVotedByLength = (data['downVotedBy'] as List?)?.length ?? 0;
                        data['totalVotes'] = upVotedByLength + downVotedByLength;
                      }
                      
                      return Prayer.fromFirestore(doc);
                    })
                    .toList();
                
                if (prayers.isEmpty) {
                  return _buildEnhancedEmptyState();
                }
                
                // Guardar el último documento para paginación
                if (snapshot.data!.docs.isNotEmpty) {
                  _lastVisibleDocument = snapshot.data!.docs.last;
                }
                
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(() {
                      _lastVisibleDocument = null;
                      _refreshKey++; // Incrementar la clave para forzar reconstrucción
                    });
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    cacheExtent: 500,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    itemCount: prayers.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == prayers.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      
                      return PrayerCard(prayer: prayers[index]);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePrayerModal(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
        tooltip: 'Pedir oração',
      ),
    );
  }
  
  String _getEmptyStateTitle() {
    switch (_filterBy) {
      case 'assigned':
        return 'Nenhuma oração atribuída';
      default:
        return 'Nenhuma oração disponível';
    }
  }
  
  String _getEmptyStateMessage() {
    switch (_filterBy) {
      case 'assigned':
        return 'Não foram atribuídas orações a cultos ainda';
      default:
        return 'Seja o primeiro a pedir oração';
    }
  }
  
  Stream<QuerySnapshot> _buildPrayersStream() {
    // Consulta base
    Query query = FirebaseFirestore.instance.collection('prayers');
    
    // Aplicar filtros según la selección
    if (_filterBy == 'assigned') {
      query = query.where('cultRef', isNull: false);
    }
    
    // Aplicar ordenamiento
    if (_sortBy == 'popular') {
      query = query.orderBy('score', descending: true)
                   .orderBy('createdAt', descending: true);
    } else {
      query = query.orderBy('createdAt', descending: true);
    }
    
    // Limitar resultados iniciales
    query = query.limit(15);
    
    return query.snapshots();
  }

  void _showCreatePrayerModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const CreatePrayerModal(),
    );
  }
  
  Widget _buildEnhancedEmptyState() {
    IconData stateIcon;
    Color iconColor;
    
    if (_filterBy == 'assigned') {
      stateIcon = Icons.church;
      iconColor = Colors.blue;
    } else {
      stateIcon = _sortBy == 'popular' ? Icons.trending_up : Icons.access_time;
      iconColor = AppColors.primary;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                stateIcon,
                size: 80,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _getEmptyStateTitle(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _getEmptyStateMessage(),
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.7,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => _showCreatePrayerModal(context),
                icon: const Icon(Icons.add, size: 24),
                label: Text(
                  'Pedir oração',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shadowColor: AppColors.primary.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 