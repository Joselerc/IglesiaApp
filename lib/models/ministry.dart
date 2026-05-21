import 'package:cloud_firestore/cloud_firestore.dart';

class Ministry {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> adminIds;
  final List<String> memberIds;
  final Map<String, dynamic> pendingRequests; // userId: timestamp
  final Map<String, dynamic> rejectedRequests; // userId: timestamp
  final DateTime createdAt;
  final DateTime updatedAt;

  Ministry({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.adminIds,
    required this.memberIds,
    required this.pendingRequests,
    required this.rejectedRequests,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ministry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    String? extractUserId(dynamic value) {
      if (value is DocumentReference) return value.id;
      if (value is Map && value['path'] != null) {
        return value['path'].toString().split('/').last;
      }
      if (value is String) {
        final parts = value.split('/').where((part) => part.isNotEmpty).toList();
        return parts.isEmpty ? value : parts.last;
      }
      return value?.toString();
    }
    
    // Convertir referencias de documentos a IDs de string
    List<String> memberIds = [];
    if (data['members'] != null) {
      final members = data['members'] as List?;
      if (members != null) {
        memberIds = members
            .map(extractUserId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();
      }
    }
    
    List<String> adminIds = [];
    if (data['ministrieAdmin'] != null) {
      final admins = data['ministrieAdmin'] as List?;
      if (admins != null) {
        adminIds = admins
            .map(extractUserId)
            .whereType<String>()
            .where((id) => id.isNotEmpty)
            .toList();
      }
    }
    final creatorId = extractUserId(data['createdBy']);
    if (creatorId != null && creatorId.isNotEmpty && !adminIds.contains(creatorId)) {
      adminIds.add(creatorId);
    }
    
    // Manejar correctamente los Timestamps
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        // Intentar parsear la fecha si es una cadena
        try {
          createdAt = DateTime.parse(data['createdAt']);
        } catch (e) {
          print('Error parsing createdAt: $e');
        }
      }
    }
    
    // Si no hay updatedAt, usar createdAt
    DateTime updatedAt = createdAt;
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      }
    }
    
    return Ministry(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      adminIds: adminIds,
      memberIds: memberIds,
      pendingRequests: data['pendingRequests'] ?? {},
      rejectedRequests: data['rejectedRequests'] ?? {},
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'adminIds': adminIds,
      'memberIds': memberIds,
      'pendingRequests': pendingRequests,
      'rejectedRequests': rejectedRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  bool isAdmin(String userId) {
    return adminIds.contains(userId);
  }

  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  bool hasPendingRequest(String userId) {
    return pendingRequests.containsKey(userId) && pendingRequests[userId] != null;
  }

  bool hasRejectedRequest(String userId) {
    return rejectedRequests.containsKey(userId);
  }

  String getUserStatus(String userId) {
    if (isAdmin(userId) || isMember(userId)) {
      return 'Enter';
    } else if (hasPendingRequest(userId)) {
      return 'Pending';
    }
    return 'Solicit to Join';
  }

  Ministry copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? adminIds,
    List<String>? memberIds,
    Map<String, dynamic>? pendingRequests,
    Map<String, dynamic>? rejectedRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ministry(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      adminIds: adminIds ?? this.adminIds,
      memberIds: memberIds ?? this.memberIds,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      rejectedRequests: rejectedRequests ?? this.rejectedRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
} 