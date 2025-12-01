import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../services/notification_service.dart';
import '../models/notification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';

enum PostEntityType { ministry, group }

class CreatePostScreen extends StatefulWidget {
  final List<XFile> initialImages;
  final String entityId;
  final PostEntityType entityType;

  const CreatePostScreen({
    super.key,
    required this.initialImages,
    required this.entityId,
    required this.entityType,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  List<DocumentReference> _taggedUsers = [];
  String? _location; // Nombre de la ubicacion
  final PageController _imagesPageController = PageController();
  int _currentImagePage = 0;
  String? _entityNameCache;

  @override
  void initState() {
    super.initState();
    _processInitialImages();
  }

  Future<String?> _fetchEntityName() async {
    try {
      final collection = widget.entityType == PostEntityType.ministry ? 'ministries' : 'groups';
      final snap = await FirebaseFirestore.instance.collection(collection).doc(widget.entityId).get();
      if (snap.exists) {
        final data = snap.data();
        return data?['name'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> _processInitialImages() async {
    setState(() => _isLoading = true);
    for (var xfile in widget.initialImages) {
      final file = File(xfile.path);
      // Intentar comprimir
      try {
        final compressed = await ImageService().compressImage(file, quality: 85);
        _selectedImages.add(compressed ?? file);
      } catch (e) {
        _selectedImages.add(file);
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _addMoreImages() async {
    final picker = ImagePicker();
    final picks = await picker.pickMultiImage();
    if (picks.isEmpty) return;

    setState(() => _isLoading = true);
    for (var image in picks) {
      final file = File(image.path);
      try {
        final compressed = await ImageService().compressImage(file, quality: 85);
        _selectedImages.add(compressed ?? file);
      } catch (e) {
        _selectedImages.add(file);
      }
    }
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _imagesPageController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _createPost() async {
    if (_isLoading) return; // evitar envíos dobles mientras se sube
    if (_selectedImages.isEmpty && _captionController.text.isEmpty) {
      return;
    }

    final l10n = AppLocalizations.of(context)!;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() => _isLoading = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('No user logged in');
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // 1. Subir Imágenes
      final List<String> imageUrls = [];
      final folderName = widget.entityType == PostEntityType.ministry
          ? 'ministry_posts'
          : 'group_posts';

      for (final imageFile in _selectedImages) {
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.path.split('/').last}';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child(folderName)
            .child(widget.entityId)
            .child(fileName);

        final metadata = SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'uploadedBy': userId,
          },
        );

        await storageRef.putFile(imageFile, metadata);
        final url = await storageRef.getDownloadURL();
        imageUrls.add(url);
      }

      // 2. Crear Documento en Firestore
      final collectionName = widget.entityType == PostEntityType.ministry
          ? 'ministry_posts'
          : 'group_posts';

      final entityField = widget.entityType == PostEntityType.ministry
          ? 'ministryId'
          : 'groupId';

      final entityRef = FirebaseFirestore.instance
          .collection(widget.entityType == PostEntityType.ministry ? 'ministries' : 'groups')
          .doc(widget.entityId);
      _entityNameCache ??= await _fetchEntityName();

      final postData = {
        entityField: entityRef,
        'authorId': userRef,
        'contentText': _captionController.text.trim(),
        'imageUrls': imageUrls,
        'aspectRatio': 'AspectRatioOption.square', // Default por simplicidad en este flujo, o calcular
        'createdAt': FieldValue.serverTimestamp(),
        'likes': [],
        'savedBy': [],
        'shares': [],
        'comments': [],
        'commentCount': 0,
        'taggedUsers': _taggedUsers,
        'location': _location,
      };

      final postRef = await FirebaseFirestore.instance.collection(collectionName).add(postData);

      // 3. Notificaciones a etiquetados
      if (_taggedUsers.isNotEmpty) {
        final notifService = NotificationService();
        final thumbUrl = imageUrls.isNotEmpty ? imageUrls.first : null;
        final snippet = _captionController.text.trim();

        for (final taggedUserRef in _taggedUsers) {
          if (taggedUserRef.id == userId) continue;
          await notifService.createNotification(
            title: l10n.taggedNotificationTitle,
            message: snippet.isNotEmpty ? snippet : l10n.taggedNotificationFallbackMessage,
            type: NotificationType.taggedPost,
            userId: taggedUserRef.id,
            senderId: userId,
            imageUrl: thumbUrl,
            entityId: postRef.id,
            entityType: widget.entityType == PostEntityType.ministry ? 'ministry_post' : 'group_post',
            ministryId: widget.entityType == PostEntityType.ministry ? widget.entityId : null,
            groupId: widget.entityType == PostEntityType.group ? widget.entityId : null,
            data: {
              'postId': postRef.id,
              'entityId': widget.entityId,
              'entityType': widget.entityType == PostEntityType.ministry ? 'ministry' : 'group',
              'entityName': _entityNameCache ?? '',
              'imageUrl': thumbUrl,
              'snippet': snippet,
            },
          );
        }
      }

      if (mounted) {
        navigator.pop(); // Cerrar CreatePostScreen
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(l10n.postCreatedSuccessfully)),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTagPeopleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TagPeopleSheet(
        initialTags: _taggedUsers,
        entityId: widget.entityId,
        entityType: widget.entityType,
        onTagsChanged: (tags) {
          setState(() => _taggedUsers = tags);
        },
      ),
    );
  }

  void _showLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _LocationSheet(
        onLocationSelected: (locName) {
          setState(() => _location = locName);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          l10n.newPost,
          maxLines: 2,
          overflow: TextOverflow.visible,
        ),
        centerTitle: false,
        actions: const [],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Material(
              color: Colors.white,
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                height: 240,
                child: _selectedImages.isEmpty
                    ? Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _addMoreImages,
                          child: Container(
                            width: 140,
                            height: 140,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: const Icon(Icons.add_photo_alternate_outlined, size: 40, color: Colors.grey),
                          ),
                        ),
                      )
                    : Stack(
                        children: [
                          PageView.builder(
                            controller: _imagesPageController,
                            itemCount: _selectedImages.length,
                            onPageChanged: (index) => setState(() => _currentImagePage = index),
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _selectedImages[index],
                                        cacheWidth: 1200,
                                        cacheHeight: 1200,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedImages.removeAt(index);
                                              if (_currentImagePage >= _selectedImages.length) {
                                                _currentImagePage = _selectedImages.isEmpty ? 0 : _selectedImages.length - 1;
                                              }
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.black54,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: GestureDetector(
                              onTap: _isLoading ? null : _addMoreImages,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  shape: BoxShape.circle,
                                ),
                                padding: const EdgeInsets.all(10),
                                child: const Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                          ),
                          if (_selectedImages.length > 1)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(_selectedImages.length, (i) {
                                  final active = _currentImagePage == i;
                                  return Container(
                                    width: active ? 10 : 8,
                                    height: active ? 10 : 8,
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: active ? Colors.white : Colors.white70,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.2),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              elevation: 0,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _captionController,
                  decoration: InputDecoration(
                    hintText: l10n.whatDoYouWantToShare,
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey[500], fontSize: 16),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 16, height: 1.4),
                  maxLines: null,
                  minLines: 3,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Material(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(l10n.tagPeople),
                    subtitle: _taggedUsers.isNotEmpty
                        ? Text(
                            l10n.taggedCount(_taggedUsers.length),
                            style: TextStyle(color: Colors.grey[700]),
                          )
                        : null,
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showTagPeopleSheet,
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined),
                    title: Text(l10n.addLocation),
                    subtitle: _location != null
                        ? Text(_location!, style: TextStyle(color: Colors.grey[700]))
                        : null,
                    trailing: _location != null
                        ? IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() => _location = null),
                          )
                        : const Icon(Icons.chevron_right, color: Colors.grey),
                    onTap: _showLocationSheet,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _createPost,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : Text(l10n.publish, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Sub-Widgets (Sheets) ---

class _TagPeopleSheet extends StatefulWidget {
  final List<DocumentReference> initialTags;
  final Function(List<DocumentReference>) onTagsChanged;
  final String entityId;
  final PostEntityType entityType;

  const _TagPeopleSheet({
    required this.initialTags,
    required this.onTagsChanged,
    required this.entityId,
    required this.entityType,
  });

  @override
  State<_TagPeopleSheet> createState() => _TagPeopleSheetState();
}

class _TagPeopleSheetState extends State<_TagPeopleSheet> {
  late List<DocumentReference> _selected;
  String _query = "";
  List<_TaggableUser> _options = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = List.from(widget.initialTags);
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    try {
      final collection = widget.entityType == PostEntityType.ministry ? 'ministries' : 'groups';
      final adminField = widget.entityType == PostEntityType.ministry ? 'ministrieAdmin' : 'groupAdmin';
      final doc = await FirebaseFirestore.instance.collection(collection).doc(widget.entityId).get();
      if (!doc.exists) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final data = doc.data() as Map<String, dynamic>;
      final members = (data['members'] as List?) ?? [];
      final admins = (data[adminField] as List?) ?? [];
      final userIds = <String>{};

      void addId(dynamic entry) {
        if (entry is DocumentReference) {
          userIds.add(entry.id);
        } else if (entry is String) {
          userIds.add(entry.startsWith('/users/') ? entry.split('/').last : entry);
        }
      }

      for (final m in members) {
        addId(m);
      }
      for (final a in admins) {
        addId(a);
      }

      final usersCollection = FirebaseFirestore.instance.collection('users');
      final List<_TaggableUser> loaded = [];
      for (final id in userIds) {
        final snap = await usersCollection.doc(id).get();
        if (snap.exists) {
          final uData = snap.data() as Map<String, dynamic>;
          loaded.add(_TaggableUser(
            ref: usersCollection.doc(id),
            name: (uData['name'] ?? uData['displayName'] ?? 'Usuario') as String,
            photoUrl: uData['photoUrl'] as String?,
          ));
        }
      }

      loaded.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      setState(() {
        _options = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error cargando miembros';
      });
    }
  }

  List<_TaggableUser> get _filteredUsers {
    if (_query.isEmpty) return _options;
    final lower = _query.toLowerCase();
    return _options.where((u) => u.name.toLowerCase().contains(lower)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tagPeople),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              widget.onTagsChanged(_selected);
              Navigator.pop(context);
            },
          )
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: l10n.searchUsers,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) => setState(() => _query = val),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.entityType == PostEntityType.ministry
                    ? l10n.onlyMembersOfMinistry
                    : l10n.onlyMembersOfGroup,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Text(
                            _error ?? "No hay miembros disponibles para etiquetar",
                            style: TextStyle(color: Colors.grey[600]),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredUsers.length,
                        itemBuilder: (context, index) {
                          final option = _filteredUsers[index];
                          final isSelected = _selected.any((ref) => ref.id == option.ref.id);

                          return CheckboxListTile(
                            value: isSelected,
                            title: Text(option.name),
                            secondary: CircleAvatar(
                              backgroundImage: option.photoUrl != null
                                  ? CachedNetworkImageProvider(option.photoUrl!)
                                  : null,
                              child: option.photoUrl == null ? const Icon(Icons.person) : null,
                            ),
                            onChanged: (val) {
                              setState(() {
                                if (val == true && !isSelected) {
                                  _selected.add(option.ref);
                                } else if (val == false) {
                                  _selected.removeWhere((ref) => ref.id == option.ref.id);
                                }
                              });
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _TaggableUser {
  final DocumentReference ref;
  final String name;
  final String? photoUrl;

  _TaggableUser({
    required this.ref,
    required this.name,
    this.photoUrl,
  });
}

class _LocationSheet extends StatefulWidget {
  final Function(String) onLocationSelected;

  const _LocationSheet({required this.onLocationSelected});

  @override
  State<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends State<_LocationSheet> {
  String _query = "";
  final Dio _dio = Dio();
  List<Map<String, dynamic>> _globalResults = [];
  Timer? _debounce;
  bool _isSearchingGlobal = false;

  void _onSearchChanged(String query) {
    setState(() => _query = query);
    
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.length < 3) {
      setState(() {
        _globalResults = [];
        _isSearchingGlobal = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _searchGlobalPlaces(query);
    });
  }

  Future<void> _searchGlobalPlaces(String query) async {
    setState(() => _isSearchingGlobal = true);
    try {
      // Usamos OpenStreetMap (Nominatim) que es gratuito y no requiere API Key para pruebas
      final response = await _dio.get(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': query,
          'format': 'json',
          'addressdetails': 1,
          'limit': 5,
          'accept-language': 'es', // Preferir resultados en español
        },
        options: Options(
          headers: {
            'User-Agent': 'MasIglesiaApp/1.0', // Requerido por Nominatim
          },
        ),
      );

      if (response.statusCode == 200 && mounted) {
        final List data = response.data;
        setState(() {
          _globalResults = data.map((item) {
            final address = item['address'] ?? {};
            String subtitle = '';
            if (address['city'] != null) subtitle += address['city'];
            if (address['country'] != null) subtitle += (subtitle.isNotEmpty ? ', ' : '') + address['country'];
            
            return {
              'name': item['name'] ?? item['display_name'].split(',')[0],
              'address': subtitle.isNotEmpty ? subtitle : item['display_name'],
              'isGlobal': true,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error searching places: $e');
    } finally {
      if (mounted) setState(() => _isSearchingGlobal = false);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                TextField(
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: l10n.searchLocationHint,
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: _onSearchChanged,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: CustomScrollView(
              slivers: [
                // 1. Ubicaciones Guardadas (Firebase)
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('locations').limit(20).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SliverToBoxAdapter(child: SizedBox());

                    final docs = snapshot.data!.docs.where((doc) {
                       final data = doc.data() as Map<String, dynamic>;
                       final name = (data['name'] ?? '').toString().toLowerCase();
                       return _query.isEmpty || name.contains(_query.toLowerCase());
                    }).toList();

                    if (docs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == 0) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              color: Colors.grey[50],
                              child: Text(
                                "Ubicaciones Guardadas",
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            );
                          }
                          final doc = docs[index - 1];
                          final data = doc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.grey[100],
                              child: const Icon(Icons.bookmark, color: Colors.orange, size: 20),
                            ),
                            title: Text(data['name'] ?? 'Ubicación'),
                            subtitle: Text(data['address'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              widget.onLocationSelected(data['name'] ?? '');
                              Navigator.pop(context);
                            },
                          );
                        },
                        childCount: docs.length + 1,
                      ),
                    );
                  },
                ),

                // 2. Resultados Globales (API)
                if (_query.isNotEmpty)
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == 0) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            color: Colors.grey[50],
                            child: Row(
                              children: [
                                Text(
                                  "Resultados Globales",
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                if (_isSearchingGlobal) ...[
                                  const SizedBox(width: 8),
                                  const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ]
                              ],
                            ),
                          );
                        }
                        
                        if (_globalResults.isEmpty && !_isSearchingGlobal && index == 1) {
                          return Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              "No se encontraron resultados globales",
                              style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          );
                        }

                        if (_globalResults.isEmpty) return const SizedBox();

                        final item = _globalResults[index - 1];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.grey[100],
                            child: const Icon(Icons.public, color: Colors.blue, size: 20),
                          ),
                          title: Text(item['name']),
                          subtitle: Text(item['address'], maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            widget.onLocationSelected(item['name']);
                            Navigator.pop(context);
                          },
                        );
                      },
                      childCount: _globalResults.isEmpty ? 2 : _globalResults.length + 1,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
