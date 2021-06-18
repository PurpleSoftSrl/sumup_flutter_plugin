import 'sumup_payment.dart';

/// Sumup payment request
class SumupPaymentRequest {
  SumupPaymentRequest(this.payment, {this.info});

  SumupPayment payment;

  /// All the additional information associated with this payment
  Map<String, String>? info;

  Map<String, dynamic> toMap() => {
        'payment': payment.toMap(),
        'info': info,
      };
}
