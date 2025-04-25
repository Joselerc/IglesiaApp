import 'package:cloud_firestore/cloud_firestore.dart';

class WorkAssignment {
  final String id;
  final String timeSlotId;
  final String ministryId;
  final String userId;
  final String role;
  final String status; // pending, accepted, rejected, seen, confirmed
  final DateTime createdAt;
  final DateTime? respondedAt;
  final String invitedBy;
  final String? notes;
  final bool isActive;
  final bool isConfirmed; // Campo obsoleto - no se usa para determinar confirmación
  final bool isAttendanceConfirmed; // Se usa junto con status para determinar si está confirmado

  WorkAssignment({
    required this.id,
    required this.timeSlotId,
    required this.ministryId,
    required this.userId,
    required this.role,
    required this.status,
    required this.createdAt,
    this.respondedAt,
    required this.invitedBy,
    this.notes,
    this.isActive = true,
    this.isConfirmed = false,
    this.isAttendanceConfirmed = false,
  });

  factory WorkAssignment.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Extraer ministryId que puede ser un string o una referencia
    String ministryId = '';
    final ministryRef = data['ministryId'];
    if (ministryRef is DocumentReference) {
      ministryId = ministryRef.id;
    } else if (ministryRef is String && ministryRef.startsWith('/ministries/')) {
      ministryId = ministryRef.substring('/ministries/'.length);
    } else if (ministryRef is String) {
      ministryId = ministryRef;
    }
    
    // Extraer userId que puede ser un string o una referencia
    String userId = '';
    final userRef = data['userId'];
    if (userRef is DocumentReference) {
      userId = userRef.id;
    } else if (userRef is String && userRef.startsWith('/users/')) {
      userId = userRef.substring('/users/'.length);
    } else if (userRef is String) {
      userId = userRef;
    }
    
    // Extraer invitedBy que puede ser un string o una referencia
    String invitedById = '';
    final invitedByRef = data['invitedBy'];
    if (invitedByRef is DocumentReference) {
      invitedById = invitedByRef.id;
    } else if (invitedByRef is String && invitedByRef.startsWith('/users/')) {
      invitedById = invitedByRef.substring('/users/'.length);
    } else if (invitedByRef is String) {
      invitedById = invitedByRef;
    }
    
    // Normalizar el status (manejar tanto inglés como español)
    String status = data['status'] ?? 'pending';
    if (status == 'confirmado') {
      status = 'confirmed';
    }
    
    print('🔄 WorkAssignment para ministerio=$ministryId, usuario=$userId, status=$status');
    
    return WorkAssignment(
      id: doc.id,
      timeSlotId: data['timeSlotId'] ?? '',
      ministryId: ministryId,
      userId: userId,
      role: data['role'] ?? '',
      status: status,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      respondedAt: (data['respondedAt'] as Timestamp?)?.toDate(),
      invitedBy: invitedById,
      notes: data['notes'],
      isActive: data['isActive'] ?? true,
      isConfirmed: data['isConfirmed'] ?? false,
      isAttendanceConfirmed: data['isAttendanceConfirmed'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'timeSlotId': timeSlotId,
      'ministryId': FirebaseFirestore.instance.collection('ministries').doc(ministryId),
      'userId': FirebaseFirestore.instance.collection('users').doc(userId),
      'role': role,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'invitedBy': FirebaseFirestore.instance.collection('users').doc(invitedBy),
      'isActive': isActive,
      'isConfirmed': isConfirmed,
      'isAttendanceConfirmed': isAttendanceConfirmed,
    };

    // Solo añadir si no son nulos
    if (respondedAt != null) {
      map['respondedAt'] = Timestamp.fromDate(respondedAt!);
    }
    if (notes != null) {
      map['notes'] = notes as Object;
    }

    return map;
  }

  // Método para crear una copia del objeto con nuevos valores
  WorkAssignment copyWith({
    String? id,
    String? timeSlotId,
    String? ministryId,
    String? userId,
    String? role,
    String? status,
    DateTime? createdAt,
    DateTime? respondedAt,
    String? invitedBy,
    String? notes,
    bool? isActive,
    bool? isConfirmed,
    bool? isAttendanceConfirmed,
  }) {
    return WorkAssignment(
      id: id ?? this.id,
      timeSlotId: timeSlotId ?? this.timeSlotId,
      ministryId: ministryId ?? this.ministryId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isConfirmed: isConfirmed ?? this.isConfirmed,
      isAttendanceConfirmed: isAttendanceConfirmed ?? this.isAttendanceConfirmed,
    );
  }
} 