// lib/models/cult_ministry.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CultMinistry {
  final String id;
  final String cultId;
  final String? ministryId; // Puede ser null si es temporal
  final String name;
  final DateTime startTime;
  final DateTime endTime;
  final bool isTemporary;
  final List<CultMinistryMember> members;
  final String? description;

  CultMinistry({
    required this.id,
    required this.cultId,
    this.ministryId,
    required this.name,
    required this.startTime,
    required this.endTime,
    required this.isTemporary,
    required this.members,
    this.description,
  });

  factory CultMinistry.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Convertir la lista de miembros
    List<CultMinistryMember> members = [];
    if (data['members'] != null && data['members'] is List) {
      members = (data['members'] as List).map((member) {
        return CultMinistryMember(
          userId: member['userId'] ?? '',
          role: member['role'] ?? '',
          startTime: (member['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
          endTime: (member['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    }
    
    return CultMinistry(
      id: doc.id,
      cultId: data['cultId']?.id ?? '',
      ministryId: data['ministryId']?.id,
      name: data['name'] ?? '',
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isTemporary: data['isTemporary'] ?? false,
      members: members,
      description: data['description'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cultId': FirebaseFirestore.instance.collection('cults').doc(cultId),
      'ministryId': ministryId != null ? FirebaseFirestore.instance.collection('ministries').doc(ministryId) : null,
      'name': name,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'isTemporary': isTemporary,
      'members': members.map((member) => member.toMap()).toList(),
      'description': description,
    };
  }
}

class CultMinistryMember {
  final String userId;
  final String role;
  final DateTime startTime;
  final DateTime endTime;

  CultMinistryMember({
    required this.userId,
    required this.role,
    required this.startTime,
    required this.endTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
    };
  }
}