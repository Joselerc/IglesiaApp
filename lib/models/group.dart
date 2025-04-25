import 'package:cloud_firestore/cloud_firestore.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final List<String> adminIds;
  final List<String> memberIds;
  final Map<String, dynamic> pendingRequests;
  final Map<String, dynamic> rejectedRequests;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
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

  factory Group.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertir referencias de documentos a IDs de string para adminIds
    List<String> adminIds = [];
    if (data['groupAdmin'] != null) {
      final admins = data['groupAdmin'] as List?;
      if (admins != null) {
        adminIds = admins.map((admin) {
          if (admin is DocumentReference) {
            return admin.id;
          } else if (admin is String && admin.startsWith('/users/')) {
            return admin.substring(7); // Quitar '/users/'
          }
          return admin.toString();
        }).toList();
      }
    }
    
    // Convertir referencias de documentos a IDs de string para memberIds
    List<String> memberIds = [];
    if (data['members'] != null) {
      final members = data['members'] as List?;
      if (members != null) {
        memberIds = members.map((member) {
          if (member is DocumentReference) {
            return member.id;
          } else if (member is String && member.startsWith('/users/')) {
            return member.substring(7); // Quitar '/users/'
          }
          return member.toString();
        }).toList();
      }
    }
    
    // Manejar correctamente los Timestamps
    DateTime createdAt = DateTime.now();
    if (data['createdAt'] != null) {
      if (data['createdAt'] is Timestamp) {
        createdAt = (data['createdAt'] as Timestamp).toDate();
      } else if (data['createdAt'] is String) {
        try {
          createdAt = DateTime.parse(data['createdAt']);
        } catch (e) {
          print('Error parsing createdAt: $e');
        }
      }
    }
    
    DateTime updatedAt = createdAt;
    if (data['updatedAt'] != null) {
      if (data['updatedAt'] is Timestamp) {
        updatedAt = (data['updatedAt'] as Timestamp).toDate();
      } else if (data['updatedAt'] is String) {
        try {
          updatedAt = DateTime.parse(data['updatedAt']);
        } catch (e) {
          print('Error parsing updatedAt: $e');
        }
      }
    }
    
    // Sugerencia de corrección para pendingRequests y rejectedRequests:
    Map<String, dynamic> pendingRequests = {};
    if (data['pendingRequests'] != null) {
      pendingRequests = Map<String, dynamic>.from(data['pendingRequests']);
    }
    
    Map<String, dynamic> rejectedRequests = {};
    if (data['rejectedRequests'] != null) {
      rejectedRequests = Map<String, dynamic>.from(data['rejectedRequests']);
    }
    
    return Group(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      adminIds: adminIds,
      memberIds: memberIds,
      pendingRequests: pendingRequests,
      rejectedRequests: rejectedRequests,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  String getUserStatus(String userId) {
    if (isAdmin(userId) || isMember(userId)) {
      return 'Enter';
    } else if (hasPendingRequest(userId)) {
      return 'Pending';
    }
    return 'Solicit to Join';
  }

  bool isAdmin(String userId) {
    return adminIds.contains(userId);
  }

  bool isMember(String userId) {
    return memberIds.contains(userId);
  }

  bool hasPendingRequest(String userId) {
    return pendingRequests.containsKey(userId);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'groupAdmin': adminIds.map((id) => FirebaseFirestore.instance.doc('/users/$id')).toList(),
      'members': memberIds.map((id) => FirebaseFirestore.instance.doc('/users/$id')).toList(),
      'pendingRequests': pendingRequests,
      'rejectedRequests': rejectedRequests,
    };
  }
} 