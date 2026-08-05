import 'package:flutter_test/flutter_test.dart';
import 'package:sumup/sumup.dart';

void main() {
  group('SumupPayment', () {
    test('serializes checkout values and normalizes the currency', () {
      final payment = SumupPayment(
        title: 'Order 42',
        total: 12.5,
        currency: 'eur',
        tip: 1.5,
        foreignTransactionId: 'order-42',
        saleItemsCount: 2,
        skipSuccessScreen: true,
        customerEmail: 'customer@example.com',
        cardType: CardType.credit,
      );

      expect(payment.toMap(), <String, dynamic>{
        'total': 12.5,
        'title': 'Order 42',
        'currency': 'EUR',
        'tip': 1.5,
        'tipOnCardReader': false,
        'skipSuccessScreen': true,
        'skipFailureScreen': false,
        'foreignTransactionId': 'order-42',
        'saleItemsCount': 2,
        'customerEmail': 'customer@example.com',
        'customerPhone': null,
        'cardType': 'credit',
      });
    });

    test('uses card reader as the default payment method', () {
      final request = SumupPaymentRequest(SumupPayment(total: 5));

      expect(request.toMap()['paymentMethod'], 'cardReader');
    });

    test('serializes Tap to Pay as the selected payment method', () {
      final request = SumupPaymentRequest(
        SumupPayment(total: 5),
        paymentMethod: PaymentMethod.tapToPay,
      );

      expect(request.toMap()['paymentMethod'], 'tapToPay');
    });
  });

  group('SumupPluginCheckoutResponse', () {
    test('parses native values independently from the host platform', () {
      final response = SumupPluginCheckoutResponse.fromMap(<String, dynamic>{
        'success': true,
        'transactionCode': 'TX-42',
        'amount': '12',
        'vatAmount': 2.5,
        'tipAmount': 1,
        'currency': 'EUR',
        'installments': '3',
        'foreignTransactionId': 'order-42',
        'receiptSent': true,
        'products': <Map<String, dynamic>>[
          <String, dynamic>{'name': 'Coffee', 'price': 3, 'quantity': 2},
        ],
      });

      expect(response.success, isTrue);
      expect(response.transactionCode, 'TX-42');
      expect(response.amount, 12.0);
      expect(response.vatAmount, 2.5);
      expect(response.tipAmount, 1.0);
      expect(response.installments, 3);
      expect(response.foreignTransactionId, 'order-42');
      expect(response.receiptSent, isTrue);
      expect(response.products, hasLength(1));
      expect(response.products!.single.name, 'Coffee');
      expect(response.products!.single.price, 3.0);
      expect(response.products!.single.quantity, 2);
    });

    test('keeps optional native values nullable', () {
      final response = SumupPluginCheckoutResponse.fromMap(<String, dynamic>{
        'success': false,
      });

      expect(response.amount, isNull);
      expect(response.installments, isNull);
      expect(response.foreignTransactionId, isNull);
      expect(response.receiptSent, isNull);
      expect(response.products, isNull);
    });
  });

  test('parses Tap to Pay availability defensively', () {
    final availability = TapToPayAvailabilityResult.fromMap(<String, dynamic>{
      'isAvailable': true,
      'isActivated': false,
      'error': 42,
    });

    expect(availability.isAvailable, isTrue);
    expect(availability.isActivated, isFalse);
    expect(availability.error, '42');
  });
}
