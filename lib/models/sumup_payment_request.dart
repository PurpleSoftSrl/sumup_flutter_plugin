import 'sumup_payment.dart';

/// Payment request object.
class SumupPaymentRequest {
  /// Creates a payment request with the given [payment] details.
  /// [paymentMethod] defaults to card reader. [info] is deprecated.
  SumupPaymentRequest(
    this.payment, {
    this.paymentMethod = PaymentMethod.cardReader,
    @Deprecated(
        'This field is not used anymore. See issue https://github.com/sumup/sumup-android-sdk/issues/166')
    this.info,
  });

  /// The payment details.
  SumupPayment payment;

  /// Payment method: card reader (default) or Tap-to-Pay.
  final PaymentMethod paymentMethod;

  /// All the additional information associated with this payment
  Map<String, String>? info;

  /// Serializes this request to a map for the native channel.
  Map<String, dynamic> toMap() => {
        'payment': payment.toMap(),
        'paymentMethod': paymentMethod.name,
      };
}
