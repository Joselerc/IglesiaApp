import 'package:cloud_firestore/cloud_firestore.dart';

class ChurchLocation {
  final String id;
  final String name;
  final String city;
  final String state;
  final String country;
  final String address; // Campo derivado o principal si existe
  final String? number;
  final String? neighborhood;
  final String? postalCode;
  final String? complement;
  final String? createdBy;
  final DateTime? createdAt;
  final bool isDefault;

  ChurchLocation({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.country,
    this.address = '',
    this.number,
    this.neighborhood,
    this.postalCode,
    this.complement,
    this.createdBy,
    this.createdAt,
    this.isDefault = false,
  });

  factory ChurchLocation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Intentar construir una dirección completa si no existe campo address
    String buildAddress() {
      if (data.containsKey('address') && data['address'].toString().isNotEmpty) {
        return data['address'];
      }
      // Construir dirección combinada
      // Se asume que 'street' podría ser el nombre de la calle si existe
      final street = data['street'] ?? ''; 
      return street;
    }

    return ChurchLocation(
      id: doc.id,
      name: data['name'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      country: data['country'] ?? 'Brasil',
      address: buildAddress(),
      number: data['number'],
      neighborhood: data['neighborhood'],
      postalCode: data['postalCode'],
      complement: data['complement'],
      createdBy: data['createdBy'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isDefault: data['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'city': city,
      'state': state,
      'country': country,
      'address': address, // O 'street' según convención
      'number': number,
      'neighborhood': neighborhood,
      'postalCode': postalCode,
      'complement': complement,
      'createdBy': createdBy,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isDefault': isDefault,
    };
  }
  
  String get fullAddress {
    final parts = [
      address,
      number != null && number!.isNotEmpty ? 'nº $number' : null,
      neighborhood != null && neighborhood!.isNotEmpty ? neighborhood : null,
      city,
      state
    ].where((e) => e != null && e.isNotEmpty).join(', ');
    
    return parts;
  }
}
