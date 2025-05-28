import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckinStatus { checkedIn, checkedOut, visitor }

class CheckinRecordModel {
  final String id;
  final String childId;
  final String familyId;
  final String? scheduledRoomId;
  final String? scheduledRoomDescription;
  final String? childAgeRangeAtCheckin;
  final Timestamp checkinTime;
  final Timestamp? checkoutTime;
  final CheckinStatus status; // checkedIn, checkedOut
  final String? checkedInByUserId; // UID del usuario que hizo el check-in (admin o padre)
  final String? checkedOutByUserId; // UID del usuario que hizo el check-out
  final String? checkinPhotoUrl; // Foto tomada al hacer check-in
  final String? checkoutPhotoUrl; // Foto tomada al hacer check-out
  final String? pickupGuardianName; // Nombre del adulto que recoge (si es diferente o visitante)
  final int? labelNumber; // Número de etiqueta impresa
  final bool privacyPolicyAccepted; // Si se aceptaron las políticas
  final bool isVisitor;
  final String? visitorGuardianName;
  final String? visitorGuardianPhone;
  final String? visitorGuardianEmail;

  CheckinRecordModel({
    required this.id,
    required this.childId,
    required this.familyId,
    this.scheduledRoomId,
    this.scheduledRoomDescription,
    this.childAgeRangeAtCheckin,
    required this.checkinTime,
    this.checkoutTime,
    required this.status,
    this.checkedInByUserId,
    this.checkedOutByUserId,
    this.checkinPhotoUrl,
    this.checkoutPhotoUrl,
    this.pickupGuardianName,
    this.labelNumber,
    this.privacyPolicyAccepted = false,
    this.isVisitor = false,
    this.visitorGuardianName,
    this.visitorGuardianPhone,
    this.visitorGuardianEmail,
  });

  factory CheckinRecordModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CheckinRecordModel(
      id: doc.id,
      childId: data['childId'] ?? '',
      familyId: data['familyId'] ?? '',
      scheduledRoomId: data['scheduledRoomId'] as String?,
      scheduledRoomDescription: data['scheduledRoomDescription'] as String?,
      childAgeRangeAtCheckin: data['childAgeRangeAtCheckin'] as String?,
      checkinTime: data['checkinTime'] ?? Timestamp.now(),
      checkoutTime: data['checkoutTime'] as Timestamp?,
      status: CheckinStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'checkedIn'),
        orElse: () => CheckinStatus.checkedIn,
      ),
      checkedInByUserId: data['checkedInByUserId'] as String?,
      checkedOutByUserId: data['checkedOutByUserId'] as String?,
      checkinPhotoUrl: data['checkinPhotoUrl'] as String?,
      checkoutPhotoUrl: data['checkoutPhotoUrl'] as String?,
      pickupGuardianName: data['pickupGuardianName'] as String?,
      labelNumber: data['labelNumber'] as int?,
      privacyPolicyAccepted: data['privacyPolicyAccepted'] ?? false,
      isVisitor: data['isVisitor'] ?? false,
      visitorGuardianName: data['visitorGuardianName'] as String?,
      visitorGuardianPhone: data['visitorGuardianPhone'] as String?,
      visitorGuardianEmail: data['visitorGuardianEmail'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'familyId': familyId,
      'scheduledRoomId': scheduledRoomId,
      'scheduledRoomDescription': scheduledRoomDescription,
      'childAgeRangeAtCheckin': childAgeRangeAtCheckin,
      'checkinTime': checkinTime,
      'checkoutTime': checkoutTime,
      'status': status.toString().split('.').last,
      'checkedInByUserId': checkedInByUserId,
      'checkedOutByUserId': checkedOutByUserId,
      'checkinPhotoUrl': checkinPhotoUrl,
      'checkoutPhotoUrl': checkoutPhotoUrl,
      'pickupGuardianName': pickupGuardianName,
      'labelNumber': labelNumber,
      'privacyPolicyAccepted': privacyPolicyAccepted,
      'isVisitor': isVisitor,
      'visitorGuardianName': visitorGuardianName,
      'visitorGuardianPhone': visitorGuardianPhone,
      'visitorGuardianEmail': visitorGuardianEmail,
    };
  }

  static CheckinStatus _statusFromString(String statusStr) {
    switch (statusStr.toLowerCase()) {
      case 'checkedin': return CheckinStatus.checkedIn;
      case 'checkedout': return CheckinStatus.checkedOut;
      case 'visitor': return CheckinStatus.visitor;
      default: return CheckinStatus.checkedOut; // O un estado por defecto más apropiado
    }
  }
}

// Colección en Firestore: checkinRecords 