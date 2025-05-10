import 'package:cloud_firestore/cloud_firestore.dart';

enum CheckinStatus { checkedIn, checkedOut, visitor }

class CheckinRecordModel {
  final String id;
  final String childId;
  final String familyId;
  final String roomId;
  final Timestamp checkinTime;
  final Timestamp? checkoutTime;
  final CheckinStatus status; // checkedIn, checkedOut
  final String? checkedInByUserId; // UID del usuario que hizo el check-in (admin o padre)
  final String? checkedOutByUserId; // UID del usuario que hizo el check-out
  final String? checkinPhotoUrl; // Foto tomada al hacer check-in
  final String? checkoutPhotoUrl; // Foto tomada al hacer check-out
  final String? pickupGuardianName; // Nombre del adulto que recoge (si es diferente o visitante)
  final String? labelNumber; // Número de etiqueta impresa
  final bool privacyPolicyAccepted; // Si se aceptaron las políticas
  final bool isVisitor;
  final String? visitorGuardianName;
  final String? visitorGuardianPhone;
  final String? visitorGuardianEmail;

  CheckinRecordModel({
    required this.id,
    required this.childId,
    required this.familyId,
    required this.roomId,
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
      familyId: data['familyId'] ?? '', // Podría ser nulo para visitantes puros
      roomId: data['roomId'] ?? '',
      checkinTime: data['checkinTime'] ?? Timestamp.now(),
      checkoutTime: data['checkoutTime'] as Timestamp?,
      status: _statusFromString(data['status'] ?? 'checkedOut'),
      checkedInByUserId: data['checkedInByUserId'] as String?,
      checkedOutByUserId: data['checkedOutByUserId'] as String?,
      checkinPhotoUrl: data['checkinPhotoUrl'] as String?,
      checkoutPhotoUrl: data['checkoutPhotoUrl'] as String?,
      pickupGuardianName: data['pickupGuardianName'] as String?,
      labelNumber: data['labelNumber'] as String?,
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
      'roomId': roomId,
      'checkinTime': checkinTime,
      'checkoutTime': checkoutTime,
      'status': status.toString().split('.').last, // Guarda como string
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

  static CheckinStatus _statusFromString(String status) {
    switch (status) {
      case 'checkedIn':
        return CheckinStatus.checkedIn;
      case 'visitor': // Aunque el check-in de visitante también es checkedIn, puede tener un estado diferente
        return CheckinStatus.visitor;
      case 'checkedOut':
      default:
        return CheckinStatus.checkedOut;
    }
  }
}

// Colección en Firestore: checkinRecords 