import 'package:cloud_firestore/cloud_firestore.dart';

class Prayer {
  final String id;
  final String content;
  final DateTime createdAt;
  final DocumentReference createdBy;
  final bool isAnonymous;
  final List<DocumentReference> upVotedBy;
  final List<DocumentReference> downVotedBy;
  final bool isAccepted;
  final DocumentReference? acceptedBy;
  final int score;
  final int totalVotes;
  
  // Campos para asignación a cultos
  final DocumentReference? cultRef;
  final DateTime? assignedToCultAt;
  final DocumentReference? assignedToCultBy;
  final String? cultName; // Nombre del culto para facilitar la visualización

  Prayer({
    required this.id,
    required this.content,
    required this.createdAt,
    required this.createdBy,
    required this.isAnonymous,
    required this.upVotedBy,
    required this.downVotedBy,
    required this.isAccepted,
    this.acceptedBy,
    this.score = 0,
    this.totalVotes = 0,
    this.cultRef,
    this.assignedToCultAt,
    this.assignedToCultBy,
    this.cultName,
  });

  factory Prayer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final upVotedBy = (data['upVotedBy'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [];
    final downVotedBy = (data['downVotedBy'] as List?)?.map((ref) => ref as DocumentReference).toList() ?? [];
    
    final score = upVotedBy.length - downVotedBy.length;
    final totalVotes = upVotedBy.length + downVotedBy.length;
    
    if (data['score'] != score) {
      FirebaseFirestore.instance
          .collection('prayers')
          .doc(doc.id)
          .update({'score': score})
          .catchError((e) => print('Error al actualizar score: $e'));
    }
    
    return Prayer(
      id: doc.id,
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'],
      isAnonymous: data['isAnonymous'] ?? false,
      upVotedBy: upVotedBy,
      downVotedBy: downVotedBy,
      isAccepted: data['isAccepted'] ?? false,
      acceptedBy: data['acceptedBy'],
      score: score,
      totalVotes: totalVotes,
      cultRef: data['cultRef'],
      assignedToCultAt: data['assignedToCultAt'] != null 
          ? (data['assignedToCultAt'] as Timestamp).toDate() 
          : null,
      assignedToCultBy: data['assignedToCultBy'],
      cultName: data['cultName'],
    );
  }

  Map<String, dynamic> toFirestore() {
    final map = {
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isAnonymous': isAnonymous,
      'upVotedBy': upVotedBy,
      'downVotedBy': downVotedBy,
      'isAccepted': isAccepted,
      'acceptedBy': acceptedBy,
      'score': upVotedBy.length - downVotedBy.length,
      'totalVotes': upVotedBy.length + downVotedBy.length,
    };
    
    // Añadir campos de culto solo si están presentes
    if (cultRef != null) {
      map['cultRef'] = cultRef;
      map['assignedToCultAt'] = assignedToCultAt != null 
          ? Timestamp.fromDate(assignedToCultAt!) 
          : FieldValue.serverTimestamp();
      map['assignedToCultBy'] = assignedToCultBy;
      map['cultName'] = cultName;
    }
    
    return map;
  }
  
  // Método para determinar si la oración está asignada a un culto
  bool get isAssignedToCult => cultRef != null;
  
  // Método para crear una copia de la oración con valores actualizados
  Prayer copyWith({
    String? id,
    String? content,
    DateTime? createdAt,
    DocumentReference? createdBy,
    bool? isAnonymous,
    List<DocumentReference>? upVotedBy,
    List<DocumentReference>? downVotedBy,
    bool? isAccepted,
    DocumentReference? acceptedBy,
    int? score,
    int? totalVotes,
    DocumentReference? cultRef,
    DateTime? assignedToCultAt,
    DocumentReference? assignedToCultBy,
    String? cultName,
  }) {
    return Prayer(
      id: id ?? this.id,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      upVotedBy: upVotedBy ?? this.upVotedBy,
      downVotedBy: downVotedBy ?? this.downVotedBy,
      isAccepted: isAccepted ?? this.isAccepted,
      acceptedBy: acceptedBy ?? this.acceptedBy,
      score: score ?? this.score,
      totalVotes: totalVotes ?? this.totalVotes,
      cultRef: cultRef ?? this.cultRef,
      assignedToCultAt: assignedToCultAt ?? this.assignedToCultAt,
      assignedToCultBy: assignedToCultBy ?? this.assignedToCultBy,
      cultName: cultName ?? this.cultName,
    );
  }
} 