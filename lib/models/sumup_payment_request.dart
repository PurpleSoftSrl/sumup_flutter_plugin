import 'sumup_payment.dart';

/// Payment request object.
class SumupPaymentRequest {
  SumupPaymentRequest(this.payment, {this.info});

  SumupPayment payment;

  /// All the additional information associated with this payment
  @Deprecated('This field is not used anymore. See issue https://github.com/sumup/sumup-android-sdk/issues/166')
  Map<String, String>? info;

  Map<String, dynamic> toMap() => {
        'payment': payment.toMap(),
        'info': info,
      };
}
