import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ministry.dart';
import '../../services/auth_service.dart';
import '../../services/ministry_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'ministry_feed_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/ministry_card.dart';
import '../../modals/create_ministry_modal.dart';
import '../../services/permission_service.dart';
import '../../widgets/skeletons/list_tab_content_skeleton.dart';

class MinistriesListScreen extends StatefulWidget {
  const MinistriesListScreen({super.key});

  @override
  State<MinistriesListScreen> createState() => _MinistriesListScreenState();
}

class _MinistriesListScreenState extends State<MinistriesListScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final MinistryService _ministryService = MinistryService();
  final PermissionService _permissionService = PermissionService();
  bool _isLoading = false;
  
  // Estado para saber si el usuario puede crear ministerios
  bool _canCreateMinistry = false;
  
  @override
  void initState() {
    super.initState();
    // Verificar el permiso específico
    _checkCreatePermission();
    // Intentar marcar como leídas las notificaciones "huerfanas" o mal formadas al entrar a la lista
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cleanOrphanNotifications();
    });
  }
  
  Future<void> _cleanOrphanNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Buscar notificaciones de ministerios que no se hayan limpiado
      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;

      // 1. Notificaciones genéricas de "Nuevos ministerios"
      final genericNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', whereIn: ['ministry', 'newMinistries']) 
          .get();

      for (var doc in genericNotifs.docs) {
        batch.update(doc.reference, {'isRead': true});
        hasUpdates = true;
      }

      // 2. Notificaciones de posts huérfanas (sin ministryId o mal formadas)
      // Esto busca CUALQUIER notificación de tipo ministry_post no leída y verifica si se puede limpiar
      // Como estamos en la lista general, no sabemos a qué ministerio pertenecen, pero podemos
      // verificar si el post existe. Si no existe, es basura y se borra.
      // Si existe, la dejamos (el usuario debe entrar al ministerio para borrarla y leerla).
      // PERO: Si el usuario ya está aquí, tal vez quiera "marcar todo como leído"? No, eso no es estándar.
      // Lo que haremos es reparar las notificaciones que no tengan ministryId para que el badge del Home funcione bien.
      
      final postNotifs = await FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: user.uid)
          .where('isRead', isEqualTo: false)
          .where('entityType', isEqualTo: 'ministry_post')
          .get();

      for (var doc in postNotifs.docs) {
        final data = doc.data();
        // Si no tiene ministryId, intentamos recuperarlo del post original
        if (data['ministryId'] == null && data['entityId'] != null) {
           try {
             final postId = data['entityId'] as String;
             final postDoc = await FirebaseFirestore.instance.collection('ministry_posts').doc(postId).get();
             
             if (postDoc.exists) {
               final postData = postDoc.data();
               dynamic ministryRef = postData?['ministryId'];
               String? ministryId;
               
               if (ministryRef is DocumentReference) {
                 ministryId = ministryRef.id;
               } else if (ministryRef is String) {
                 ministryId = ministryRef;
               }
               
               if (ministryId != null) {
                 // REPARACIÓN: Añadir el ministryId a la notificación para que el filtro del Home funcione
                 batch.update(doc.reference, {'ministryId': ministryId});
                 hasUpdates = true;
                 debugPrint('🔧 Reparando notificación ${doc.id}: asignando ministryId=$ministryId');
               }
             } else {
               // Si el post no existe, la notificación es basura -> borrar
               batch.update(doc.reference, {'isRead': true});
               hasUpdates = true;
               debugPrint('🗑️ Borrando notificación huérfana de post inexistente: ${doc.id}');
             }
           } catch (e) {
             debugPrint('Error verificando post para notificación ${doc.id}: $e');
           }
        }
      }

      if (hasUpdates) {
        await batch.commit();
        debugPrint('✅ MINISTRIES_LIST - Limpieza y reparación de notificaciones realizada');
      }
    } catch (e) {
      debugPrint('❌ MINISTRIES_LIST - Error en limpieza de notificaciones: $e');
    }
  }
  
  Future<void> _checkCreatePermission() async {
    // Verificar el permiso específico para crear ministerios
    final hasPermission = await _permissionService.hasPermission('create_ministry');
    if (mounted) {
      setState(() {
        _canCreateMinistry = hasPermission;
      });
    }
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  List<Ministry> _filterMinistries(List<Ministry> ministries) {
    if (_searchQuery.isEmpty) return ministries;
    return ministries.where((ministry) => 
      ministry.name.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  Future<void> _handleMinistryAction(Ministry ministry) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Você deve estar logado para entrar em um ministério')),
      );
      return;
    }

    final status = ministry.getUserStatus(user.uid);

    if (status == 'Enter') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MinistryFeedScreen(ministry: ministry),
        ),
      );
    } else if (status == 'Pending') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sua solicitação está pendente de aprovação')),
      );
    } else {
      try {
        await _ministryService.requestToJoin(ministry.id);
        
        if (mounted) {
          setState(() {
            final updatedPendingRequests = Map<String, dynamic>.from(ministry.pendingRequests);
            updatedPendingRequests[user.uid] = Timestamp.now();
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Solicitação enviada com sucesso')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).currentUser;
    final userId = user?.uid ?? '';

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
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
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Ministérios',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                    const Spacer(),
                    // Mostrar el botón de añadir solo si es pastor
                    if (_canCreateMinistry) 
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                        tooltip: 'Criar Ministério',
                        onPressed: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            builder: (context) => const CreateMinistryModal(),
                          );
                        },
                      )
                    else
                      // Placeholder para mantener el espaciado si el botón no se muestra
                      const SizedBox(width: 48), 
                  ],
                ),
              ),
            ),
          ),
          
          // Barra de búsqueda
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar ministérios...',
                hintStyle: AppTextStyles.bodyText2.copyWith(color: AppColors.textSecondary),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.3)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: AppTextStyles.bodyText2.copyWith(color: AppColors.textPrimary),
            ),
          ),
          
          // Contenido principal
          Expanded(
            child: StreamBuilder<List<Ministry>>(
              stream: _ministryService.getMinistries(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Erro: ${snapshot.error}',
                      style: AppTextStyles.bodyText1.copyWith(color: AppColors.error),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTabContentSkeleton();
                }

                try {
                  final ministries = snapshot.data ?? [];
                  final filteredMinistries = _filterMinistries(ministries);

                  if (filteredMinistries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.group_off, size: 64, color: AppColors.mutedGray),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhum ministério encontrado',
                            style: AppTextStyles.subtitle1.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredMinistries.length,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    itemBuilder: (context, index) {
                      final ministry = filteredMinistries[index];

                      return MinistryCard(
                        ministry: ministry,
                        userId: userId,
                        onActionPressed: _handleMinistryAction,
                      );
                    },
                  );
                } catch (e) {
                  return Center(
                    child: Text(
                      'Erro ao processar dados: ${e.toString()}',
                      style: AppTextStyles.bodyText1.copyWith(color: AppColors.error),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      // Mostrar el FAB solo si es pastor
      floatingActionButton: _canCreateMinistry 
          ? FloatingActionButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const CreateMinistryModal(),
                );
              },
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.add),
              tooltip: 'Criar Ministério',
            )
          : null, // Ocultar si no es pastor
    );
  }
}
