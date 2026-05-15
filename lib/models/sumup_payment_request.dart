import 'sumup_payment.dart';

/// Payment request object.
class SumupPaymentRequest {
  SumupPaymentRequest(
    this.payment, {
    this.paymentMethod = PaymentMethod.cardReader,
    @Deprecated(
        'This field is not used anymore. See issue https://github.com/sumup/sumup-android-sdk/issues/166')
    this.info,
  });

  SumupPayment payment;

  /// Payment method: card reader (default) or Tap-to-Pay.
  final PaymentMethod paymentMethod;

  /// All the additional information associated with this payment
  Map<String, String>? info;

  Map<String, dynamic> toMap() => {
        'payment': payment.toMap(),
        'paymentMethod': paymentMethod.name,
      };
}
