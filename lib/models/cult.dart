// lib/models/cult.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Cult {
  final String id;
  final String serviceId;
  final String name;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String status; // planificado, en_curso, finalizado
  final String? churchId; // Opcional para mantener compatibilidad con datos existentes
  final DocumentReference createdBy;
  final DateTime? createdAt;

  Cult({
    required this.id,
    required this.serviceId,
    required this.name,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.churchId, // Ahora es opcional
    required this.createdBy,
    this.createdAt,
  });

  factory Cult.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    debugPrint('Datos del culto ${doc.id}: $data');
    
    // Manejar serviceId que puede venir como DocumentReference o string
    String serviceId = '';
    if (data['serviceId'] is DocumentReference) {
      serviceId = data['serviceId'].id;
      debugPrint('serviceId es DocumentReference: $serviceId');
    } else if (data['serviceId'] is String) {
      serviceId = data['serviceId'];
      debugPrint('serviceId es String: $serviceId');
    } else {
      debugPrint('serviceId es tipo desconocido: ${data['serviceId']}');
    }
    
    // Manejar churchId que puede venir como DocumentReference, string o no existir
    String? churchId;
    if (data['churchId'] == null) {
      debugPrint('churchId no existe en este documento');
    } else if (data['churchId'] is DocumentReference) {
      churchId = data['churchId'].id;
      debugPrint('churchId es DocumentReference: $churchId');
    } else if (data['churchId'] is String) {
      churchId = data['churchId'];
      debugPrint('churchId es String: $churchId');
    } else {
      debugPrint('churchId es tipo desconocido: ${data['churchId']}');
    }
    
    return Cult(
      id: doc.id,
      serviceId: serviceId,
      name: data['name'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'planificado',
      churchId: churchId,
      createdBy: data['createdBy'] ?? FirebaseFirestore.instance.collection('users').doc(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'serviceId': FirebaseFirestore.instance.collection('services').doc(serviceId),
      'name': name,
      'date': Timestamp.fromDate(date),
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'status': status,
      'createdBy': createdBy,
    };
    
    // Solo añadir churchId si no es null
    if (churchId != null && churchId!.isNotEmpty) {
      map['churchId'] = FirebaseFirestore.instance.collection('churches').doc(churchId!);
    }
    
    return map;
  }
}