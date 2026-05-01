import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentCustomerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getCustomerData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return {};

    final data = doc.data() ?? {};
    final paymentProfile = Map<String, dynamic>.from(data['paymentProfile'] ?? {});
    final paymentAddress = Map<String, dynamic>.from(paymentProfile['address'] ?? {});

    final displayName = (data['displayName'] as String?)?.trim();
    final name = (data['name'] as String?)?.trim();
    final surname = (data['surname'] as String?)?.trim();
    final fallbackName = [
      if (name != null && name.isNotEmpty) name,
      if (surname != null && surname.isNotEmpty) surname,
    ].join(' ').trim();

    return {
      'name': paymentProfile['name'] ?? (displayName?.isNotEmpty == true ? displayName : fallbackName),
      'email': paymentProfile['email'] ?? data['email'],
      'identity': paymentProfile['identity'] ?? data['cpf'] ?? data['cnpj'] ?? data['identity'],
      'phone': paymentProfile['phone'] ?? data['phoneComplete'] ?? data['phone'],
      'cityIbge': paymentProfile['cityIbge'] ?? paymentAddress['cityIbge'],
      'address': {
        'zipCode': paymentAddress['zipCode'],
        'street': paymentAddress['street'],
        'number': paymentAddress['number'],
        'district': paymentAddress['district'],
        'complement': paymentAddress['complement'],
        'cityName': paymentAddress['cityName'],
        'stateInitials': paymentAddress['stateInitials'],
        'countryName': paymentAddress['countryName'],
      },
    };
  }

  Future<void> saveCustomerData(String uid, Map<String, dynamic> data) async {
    final address = Map<String, dynamic>.from(data['address'] ?? {});
    await _firestore.collection('users').doc(uid).set(
      {
        'paymentProfile': {
          'name': data['name'],
          'email': data['email'],
          'identity': data['identity'],
          'phone': data['phone'],
          'cityIbge': data['cityIbge'],
          'address': address,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      },
      SetOptions(merge: true),
    );
  }

  static Set<String> getMissingFields(
    Map<String, dynamic> data, {
    bool requireCityIbge = false,
  }) {
    final missing = <String>{};

    final name = (data['name'] as String?)?.trim();
    final identity = (data['identity'] as String?)?.trim();
    final phone = (data['phone'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();
    final address = Map<String, dynamic>.from(data['address'] ?? {});

    if (name == null || name.isEmpty) missing.add('name');
    if (identity == null || identity.isEmpty) missing.add('identity');
    if (phone == null || phone.isEmpty) missing.add('phone');
    if (email == null || email.isEmpty) missing.add('email');

    void checkAddressField(String key) {
      final value = (address[key] as String?)?.trim();
      if (value == null || value.isEmpty) missing.add('address.$key');
    }

    checkAddressField('zipCode');
    checkAddressField('street');
    checkAddressField('number');
    checkAddressField('district');
    checkAddressField('cityName');
    checkAddressField('stateInitials');
    checkAddressField('countryName');

    if (requireCityIbge) {
      final cityIbge = (data['cityIbge'] as String?)?.trim();
      if (cityIbge == null || cityIbge.isEmpty) {
        missing.add('cityIbge');
      }
    }

    return missing;
  }
}
