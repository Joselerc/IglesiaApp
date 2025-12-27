import 'package:cloud_firestore/cloud_firestore.dart';

/// Nuevo modelo para la funcionalidad de "Familias" (independiente de MyKids).
/// Cada familia agrupa usuarios con roles internos y estados de membresía.
class FamilyGroup {
  final String id;
  final String name;
  final String creatorId;
  final String description;
  final String photoUrl;
  final List<String> adminIds;
  final List<String> memberIds;
  final Map<String, String> memberRoles; // userId -> role
  final Map<String, dynamic> pendingInvites; // userId -> {role, invitedBy, createdAt}
  final Map<String, dynamic> pendingRequests; // userId -> {role, createdAt, message?}
  final DateTime createdAt;
  final DateTime updatedAt;

  static const List<String> roleOptions = [
    'padre',
    'madre',
    'abuelo',
    'abuela',
    'tio',
    'tia',
    'hijo',
    'hija',
    'tutor',
    'otro',
    'admin', // rol técnico para etiquetar administradores
  ];

  const FamilyGroup({
    required this.id,
    required this.name,
    required this.creatorId,
    required this.description,
    required this.photoUrl,
    required this.adminIds,
    required this.memberIds,
    required this.memberRoles,
    required this.pendingInvites,
    required this.pendingRequests,
    required this.createdAt,
    required this.updatedAt,
  });

  bool isAdmin(String userId) => adminIds.contains(userId);

  bool isMember(String userId) => memberIds.contains(userId);

  String roleOf(String userId) => memberRoles[userId] ?? 'otro';

  factory FamilyGroup.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<String> _extractUserIds(dynamic rawList) {
      if (rawList is List) {
        return rawList.map<String>((item) {
          if (item is DocumentReference) return item.id;
          if (item is String && item.startsWith('/users/')) {
            return item.substring(7);
          }
          return item.toString();
        }).toList();
      }
      return [];
    }

    DateTime _parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {}
      }
      return DateTime.now();
    }

    return FamilyGroup(
      id: doc.id,
      name: data['name'] ?? '',
      creatorId: () {
        final creator = data['creator'] ?? data['creatorId'];
        if (creator is DocumentReference) return creator.id;
        if (creator is String && creator.startsWith('/users/')) {
          return creator.substring(7);
        }
        return (creator ?? '').toString();
      }(),
      description: data['description']?.toString() ?? '',
      photoUrl: data['photoUrl']?.toString() ?? '',
      adminIds: _extractUserIds(data['admins'] ?? data['familyAdmin']),
      memberIds: _extractUserIds(data['members']),
      memberRoles: Map<String, String>.from(data['memberRoles'] ?? {}),
      pendingInvites: Map<String, dynamic>.from(data['pendingInvites'] ?? {}),
      pendingRequests: Map<String, dynamic>.from(data['pendingRequests'] ?? {}),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt'] ?? data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    List<DocumentReference> _toUserRefs(List<String> ids) => ids
        .map((id) => FirebaseFirestore.instance.doc('/users/$id'))
        .toList();

    return {
      'name': name,
      'creator': FirebaseFirestore.instance.doc('/users/$creatorId'),
      'admins': _toUserRefs(adminIds),
      'members': _toUserRefs(memberIds),
      'memberRoles': memberRoles,
      'pendingInvites': pendingInvites,
      'pendingRequests': pendingRequests,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'photoUrl': photoUrl,
    };
  }
}
