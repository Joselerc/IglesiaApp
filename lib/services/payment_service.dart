import 'package:cloud_functions/cloud_functions.dart';

class PaymentSession {
  final String paymentId;
  final String? checkoutUrl;
  final String status;

  PaymentSession({
    required this.paymentId,
    required this.checkoutUrl,
    required this.status,
  });

  factory PaymentSession.fromMap(Map<String, dynamic> data) {
    return PaymentSession(
      paymentId: data['paymentId'] ?? '',
      checkoutUrl: data['checkoutUrl'] as String?,
      status: data['status'] ?? 'pending',
    );
  }
}

class PaymentService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<PaymentSession> createDonationPayment({
    required double amount,
    required String currency,
    required String method,
    required bool isRecurring,
    required String? receiverId,
    required String? paymentAccountId,
    required Map<String, dynamic> customerData,
  }) async {
    final callable = _functions.httpsCallable('createDonationPayment');
    final response = await callable.call({
      'amount': amount,
      'currency': currency,
      'method': method,
      'isRecurring': isRecurring,
      'receiverId': receiverId,
      'paymentAccountId': paymentAccountId,
      'customer': customerData,
    });
    return PaymentSession.fromMap(Map<String, dynamic>.from(response.data));
  }

  Future<PaymentSession> createEventPayment({
    required String eventId,
    required String ticketId,
    required double amount,
    required String currency,
    required String method,
    required Map<String, dynamic> formData,
    required String? paymentAccountId,
    required Map<String, dynamic> customerData,
  }) async {
    final callable = _functions.httpsCallable('createEventPayment');
    final response = await callable.call({
      'eventId': eventId,
      'ticketId': ticketId,
      'amount': amount,
      'currency': currency,
      'method': method,
      'formData': formData,
      'paymentAccountId': paymentAccountId,
      'customer': customerData,
    });
    return PaymentSession.fromMap(Map<String, dynamic>.from(response.data));
  }
}
