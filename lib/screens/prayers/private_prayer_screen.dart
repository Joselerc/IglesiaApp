import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/private_prayer.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/loading_indicator.dart';
import 'widgets/private_prayer_card.dart';
import 'modals/create_private_prayer_modal.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/skeletons/prayer_list_skeleton.dart';

class PrivatePrayerScreen extends StatefulWidget {
  const PrivatePrayerScreen({super.key});

  @override
  State<PrivatePrayerScreen> createState() => _PrivatePrayerScreenState();
}

class _PrivatePrayerScreenState extends State<PrivatePrayerScreen> with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController;
  bool _isLoadingMore = false;
  DocumentSnapshot? _lastDocument;
  static const int _limit = 15;
  
  // Contadores para las pestañas
  int _pendingCount = 0;
  int _acceptedCount = 0;
  int _respondedCount = 0;

  // Mapa para mantener el último documento por pestaña
  final Map<int, DocumentSnapshot?> _lastDocuments = {};
  // Mapa para mantener el estado de carga por pestaña
  final Map<int, bool> _isLoadingMoreMap = {0: false, 1: false, 2: false};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _scrollController.addListener(_onScroll);
    _updateTabCounts();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Usar el índice actual para la paginación
    final currentTabIndex = _tabController.index;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 && !(_isLoadingMoreMap[currentTabIndex] ?? false)) {
      _loadMorePrayers(currentTabIndex);
    }
  }

  Future<void> _loadMorePrayers(int tabIndex) async {
    final currentLastDocument = _lastDocuments[tabIndex];
    if (!(/*_isLoadingMoreMap[tabIndex] ?? */false) && currentLastDocument != null) { // Removido temporalmente para probar si mejora la carga
      setState(() {
        _isLoadingMoreMap[tabIndex] = true;
        // _isLoadingMore = true; // Mantenemos uno global para el indicador inferior general? O específico por tab?
      });

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser == null) return;

        final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

        // Base query
        Query query = FirebaseFirestore.instance.collection('private_prayers')
            .where('userId', isEqualTo: userRef)
            .orderBy('createdAt', descending: true);

        // Filtrar según la pestaña seleccionada
        query = _applyTabFilter(query, tabIndex);

        final querySnapshot = await query
            .startAfterDocument(currentLastDocument)
            .limit(_limit)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          // Actualizar el último documento para la pestaña específica
          _lastDocuments[tabIndex] = querySnapshot.docs.last;
        } else {
          // Si no hay más documentos, aseguramos que no intente cargar más
           _lastDocuments[tabIndex] = null; // O manejar de otra forma para indicar que no hay más
        }

        // El StreamBuilder se encargará de añadir los nuevos documentos a la UI
        // Solo necesitamos resetear el estado de carga
        if (mounted) {
          setState(() {
             _isLoadingMoreMap[tabIndex] = false;
             // _isLoadingMore = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingMoreMap[tabIndex] = false;
            // _isLoadingMore = false;
          });
        }
        debugPrint('Error cargando más oraciones para tab $tabIndex: $e');
      }
    }
  }

  void _showCreatePrayerModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      enableDrag: true,
      isDismissible: true,
      useSafeArea: true, // Para respeto más adecuado del área del teclado
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: const FractionallySizedBox(
          heightFactor: 0.7,
          child: CreatePrivatePrayerModal(),
        ),
      ),
    ).then((_) {
      // Actualizar los contadores después de crear una oración
      _updateTabCounts();
    });
  }

  // Función helper para aplicar el filtro según la pestaña
  Query _applyTabFilter(Query query, int tabIndex) {
    if (tabIndex == 1) {
      // Aceptadas pero no respondidas
      query = query.where('isAccepted', isEqualTo: true)
                  .where('pastorResponse', isNull: true);
    } else if (tabIndex == 2) {
      // Respondidas
      query = query.where('pastorResponse', isNull: false);
    } else {
      // Pendientes (no aceptadas) - Asumiendo tabIndex 0
      query = query.where('isAccepted', isEqualTo: false);
    }
    return query;
  }

  Stream<QuerySnapshot> _buildPrayersStream(int tabIndex) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      return const Stream.empty();
    }

    final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    // Base query
    Query query = FirebaseFirestore.instance.collection('private_prayers')
        .where('userId', isEqualTo: userRef)
        .orderBy('createdAt', descending: true);

    // Filtrar según la pestaña seleccionada
    query = _applyTabFilter(query, tabIndex);

    // Aplicar límite inicial
    query = query.limit(_limit);

    // Escuchar cambios
    return query.snapshots().map((snapshot) {
      // Actualizar el último documento conocido para esta pestaña al recibir datos
       if (snapshot.docs.isNotEmpty) {
         // Solo actualiza si el stream trae documentos
         // Evita resetear a null si el stream emite vacío temporalmente
          _lastDocuments[tabIndex] = snapshot.docs.last;
       } else {
         // Si el snapshot inicial está vacío, no hay documentos para empezar paginación
         _lastDocuments[tabIndex] = null;
       }
      return snapshot;
    });
  }

  String _getEmptyStateTitle(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Nenhuma oração pendente';
      case 1:
        return 'Nenhuma oração aprovada';
      case 2:
        return 'Nenhuma oração respondida';
      default:
        return 'Nenhuma oração';
    }
  }

  String _getEmptyStateMessage(int tabIndex) {
    switch (tabIndex) {
      case 0:
        return 'Todos os seus pedidos de oração foram atendidos';
      case 1:
        return 'Nenhuma oração foi aprovada sem resposta';
      case 2:
        return 'Você ainda não recebeu respostas dos pastores';
      default:
        return 'Solicite oração privada aos pastores';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
                  // Barra superior con botones
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        const Text(
                          'Minhas Orações Privadas',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          tooltip: 'Atualizar',
                          onPressed: _updateTabCounts,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Pestañas con más espacio horizontal
                  Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: Colors.white,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white.withOpacity(0.7),
                      labelStyle: AppTextStyles.subtitle2.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      labelPadding: EdgeInsets.zero,
                      indicatorWeight: 3,
                      tabs: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3 - 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '($_pendingCount)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 70,
                                child: const Text(
                                  'Pendentes',
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3 - 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '($_acceptedCount)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 70,
                                child: const Text(
                                  'Aprovadas',
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width / 3 - 10,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '($_respondedCount)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                width: 70,
                                child: const Text(
                                  'Respondidas',
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Contenido principal con pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña de Pendientes
                _buildPrayersTab(0),
                
                // Pestaña de Aceptadas
                _buildPrayersTab(1),
                
                // Pestaña de Respondidas
                _buildPrayersTab(2),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreatePrayerModal,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: 'Solicitar oração',
      ),
    );
  }
  
  Widget _buildPrayersTab(int tabIndex) {
    // Usar una ValueKey para ayudar a Flutter a diferenciar los widgets de cada tab
    return KeyedSubtree(
        key: ValueKey<int>(tabIndex),
        child: StreamBuilder<QuerySnapshot>(
          stream: _buildPrayersStream(tabIndex),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return const PrayerListSkeleton();
            }

            if (snapshot.hasError) {
              debugPrint('Error en StreamBuilder tab $tabIndex: ${snapshot.error}');
              return Center(
                child: Text('Error al cargar: ${snapshot.error}'),
              );
            }

            if (!snapshot.hasData) {
              return const PrayerListSkeleton();
            }

            final prayers = snapshot.data!.docs;
            if (prayers.isEmpty) {
              return EmptyState(
                icon: Icons.church,
                title: _getEmptyStateTitle(tabIndex),
                message: _getEmptyStateMessage(tabIndex),
                buttonText: 'Pedir oração',
                onButtonPressed: _showCreatePrayerModal,
              );
            }

            final isLoading = _isLoadingMoreMap[tabIndex] ?? false;
            return RefreshIndicator(
              onRefresh: () async {
                 // Al refrescar, reseteamos el último documento para ESTA pestaña
                 // y dejamos que el stream recargue desde el principio.
                setState(() {
                   _lastDocuments[tabIndex] = null;
                   _isLoadingMoreMap[tabIndex] = false; // Asegurar que no esté cargando
                });
                 // No necesitamos llamar a setState aquí explícitamente para el stream,
                 // porque el stream reaccionará al cambio de estado si es necesario,
                 // o simplemente el refresh del indicator fuerza la recarga del stream.
              },
              child: ListView.builder(
                 // Asociar el scroll controller SOLO a la lista visible
                 // Si el controller se comparte, puede causar problemas.
                 // Considera tener controllers separados o manejar el listener con cuidado.
                controller: _scrollController, // Ver nota arriba
                padding: const EdgeInsets.all(8),
                itemCount: prayers.length + (isLoading ? 1 : 0), // Usa el loading específico de la tab
                itemBuilder: (context, index) {
                  if (index == prayers.length) {
                    // Indicador de "cargando más" al final
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: LoadingIndicator(), // Usar el widget personalizado si existe
                      ),
                    );
                  }

                  final prayer = PrivatePrayer.fromFirestore(prayers[index]);
                  return PrivatePrayerCard(prayer: prayer);
                },
              ),
            );
          },
        ),
    );
  }

  // Actualiza los contadores de las pestañas ejecutando las consultas en paralelo
  Future<void> _updateTabCounts() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;

      final userRef = FirebaseFirestore.instance.collection('users').doc(currentUser.uid);
      final prayersCollection = FirebaseFirestore.instance.collection('private_prayers');

      // Crear los Futures para las consultas de conteo sin await
      final pendingFuture = prayersCollection
          .where('userId', isEqualTo: userRef)
          .where('isAccepted', isEqualTo: false)
          .count()
          .get();

      final acceptedFuture = prayersCollection
          .where('userId', isEqualTo: userRef)
          .where('isAccepted', isEqualTo: true)
          .where('pastorResponse', isNull: true)
          .count()
          .get();

      final respondedFuture = prayersCollection
          .where('userId', isEqualTo: userRef)
          .where('pastorResponse', isNull: false)
          .count()
          .get();

      // Ejecutar todas las consultas en paralelo y esperar los resultados
      final results = await Future.wait([
        pendingFuture,
        acceptedFuture,
        respondedFuture,
      ]);

      // Extraer los resultados (los snapshots de agregación)
      final pendingSnapshot = results[0];
      final acceptedSnapshot = results[1];
      final respondedSnapshot = results[2];

      if (mounted) {
        setState(() {
          _pendingCount = pendingSnapshot.count ?? 0;
          _acceptedCount = acceptedSnapshot.count ?? 0;
          _respondedCount = respondedSnapshot.count ?? 0;

          // Debug de contadores
          debugPrint('Contadores actualizados (paralelo):');
          debugPrint('  Pendientes: $_pendingCount');
          debugPrint('  Aceptadas: $_acceptedCount');
          debugPrint('  Respondidas: $_respondedCount');
        });
      }
    } catch (e) {
      debugPrint('Error cargando contadores en paralelo: $e');
      // Opcionalmente, mostrar un mensaje al usuario
    }
  }
} 