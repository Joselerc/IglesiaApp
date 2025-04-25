import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChurchLocation {
  final String id;
  final String name;
  final String? street;
  final String? number;
  final String? complement;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final DateTime? createdAt;
  final String? createdBy;

  ChurchLocation({
    required this.id,
    required this.name,
    this.street,
    this.number,
    this.complement,
    this.neighborhood,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.createdAt,
    this.createdBy,
  });

  factory ChurchLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {}; // Handle null data safely
    return ChurchLocation(
      id: doc.id,
      name: data['name'] ?? '',
      street: data['street'] as String?,
      number: data['number'] as String?,
      complement: data['complement'] as String?,
      neighborhood: data['neighborhood'] as String?,
      city: data['city'] as String?,
      state: data['state'] as String?,
      postalCode: data['postalCode'] as String?,
      country: data['country'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (street != null) 'street': street,
      if (number != null) 'number': number,
      if (complement != null) 'complement': complement,
      if (neighborhood != null) 'neighborhood': neighborhood,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'postalCode': postalCode,
      if (country != null) 'country': country,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      if (createdBy != null) 'createdBy': createdBy,
    };
  }

  // Helper para obtener dirección formateada
  String get formattedAddress {
    List<String> parts = [];
    if (street != null && street!.isNotEmpty) parts.add(street!);
    if (number != null && number!.isNotEmpty) parts.add(number!);
    if (neighborhood != null && neighborhood!.isNotEmpty) parts.add(neighborhood!);
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (postalCode != null && postalCode!.isNotEmpty) parts.add(postalCode!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.join(', ');
  }

  // Para mostrar en Dropdown
  @override
  String toString() {
    return name;
  }
} 