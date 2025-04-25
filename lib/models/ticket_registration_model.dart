import 'package:cloud_firestore/cloud_firestore.dart';

class TicketRegistrationModel {
  final String id;
  final String eventId;
  final String ticketId;
  final String userId;
  final String userName;
  final String userEmail;
  final String userPhone;
  final Map<String, dynamic> formData;
  final String qrCode;
  final DateTime createdAt;
  final bool isUsed;
  final DateTime? usedAt;
  final String? usedBy;
  final bool attendanceConfirmed;
  final String? attendanceType;

  TicketRegistrationModel({
    required this.id,
    required this.eventId,
    required this.ticketId,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPhone,
    required this.formData,
    required this.qrCode,
    required this.createdAt,
    required this.isUsed,
    this.usedAt,
    this.usedBy,
    this.attendanceConfirmed = false,
    this.attendanceType,
  });

  factory TicketRegistrationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Garantizar que formData sea un mapa, incluso si es nulo en Firestore
    Map<String, dynamic> formData = {};
    if (data['formData'] != null) {
      formData = Map<String, dynamic>.from(data['formData']);
    }
    
    return TicketRegistrationModel(
      id: doc.id,
      eventId: data['eventId'] ?? '',
      ticketId: data['ticketId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userEmail: data['userEmail'] ?? '',
      userPhone: data['userPhone'] ?? '',
      formData: formData,
      qrCode: data['qrCode'] ?? '',
      createdAt: data['createdAt'] != null 
          ? (data['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      isUsed: data['isUsed'] ?? false,
      usedAt: data['usedAt'] != null 
          ? (data['usedAt'] as Timestamp).toDate() 
          : null,
      usedBy: data['usedBy'],
      attendanceConfirmed: data['attendanceConfirmed'] ?? false,
      attendanceType: data['attendanceType'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'ticketId': ticketId,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'formData': formData,
      'qrCode': qrCode,
      'createdAt': Timestamp.fromDate(createdAt),
      'isUsed': isUsed,
      'usedAt': usedAt != null ? Timestamp.fromDate(usedAt!) : null,
      'usedBy': usedBy,
      'attendanceConfirmed': attendanceConfirmed,
      'attendanceType': attendanceType,
    };
  }
  
  // Helper para formatear la fecha de creación
  String get formattedDate {
    final day = createdAt.day.toString().padLeft(2, '0');
    final month = createdAt.month.toString().padLeft(2, '0');
    final year = createdAt.year;
    final hour = createdAt.hour.toString().padLeft(2, '0');
    final minute = createdAt.minute.toString().padLeft(2, '0');
    
    return '$day/$month/$year $hour:$minute';
  }
} 