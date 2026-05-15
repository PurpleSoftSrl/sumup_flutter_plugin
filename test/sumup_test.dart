import 'package:flutter_test/flutter_test.dart';
import 'package:sumup/models/sumup_payment.dart';
import 'package:sumup/models/sumup_payment_request.dart';
import 'package:sumup/models/sumup_plugin_checkout_response.dart';
import 'package:sumup/models/sumup_plugin_merchant_response.dart';
import 'package:sumup/models/sumup_plugin_response.dart';
import 'package:sumup/models/tap_to_pay_availability.dart';
import 'package:sumup/src/sumup_platform_interface.dart';

class MockSumupPlatform extends SumupPlatform {
  MockSumupPlatform() : super();

  SumupPluginResponse _ok(String method) => SumupPluginResponse.fromMap(
      <dynamic, dynamic>{'methodName': method, 'status': true, 'message': <dynamic, dynamic>{}});

  @override
  Future<SumupPluginResponse> init(String affiliateKey) {
    isInitialized = true;
    return Future.value(SumupPluginResponse.fromMap(<dynamic, dynamic>{
      'methodName': 'initSDK',
      'status': true,
      'message': <dynamic, dynamic>{'initialized': true},
    }));
  }

  @override Future<SumupPluginResponse> login() => Future.value(_ok('login'));
  @override Future<SumupPluginResponse> loginWithToken(String token) => Future.value(_ok('loginWithToken'));
  @override Future<bool?> get isLoggedIn => Future.value(true);
  @override
  Future<SumupPluginMerchantResponse> get merchant => Future.value(
      SumupPluginMerchantResponse.fromMap(<dynamic, dynamic>{'merchantCode': 'M123', 'currencyCode': 'EUR'}));
  @override Future<SumupPluginResponse> openSettings() => Future.value(_ok('openSettings'));
  @override Future<SumupPluginResponse> prepareForCheckout() => Future.value(_ok('prepareForCheckout'));
  @override Future<bool> get isTipOnCardReaderAvailable => Future.value(true);
  @override Future<bool> get isCardTypeRequired => Future.value(false);
  @override
  Future<TapToPayAvailabilityResult> checkTapToPayAvailability() =>
      Future.value(TapToPayAvailabilityResult.fromMap(<dynamic, dynamic>{'isAvailable': true, 'isActivated': true}));
  @override Future<SumupPluginResponse> presentTapToPayActivation() => Future.value(_ok('presentTapToPayActivation'));
  @override
  Future<SumupPluginCheckoutResponse> checkout(SumupPaymentRequest paymentRequest) => Future.value(
      SumupPluginCheckoutResponse.fromMap(<dynamic, dynamic>{
        'success': true, 'transactionCode': 'TX123', 'amount': 10.0, 'currency': 'EUR',
      }));
  @override Future<bool?> get isCheckoutInProgress => Future.value(false);
  @override Future<SumupPluginResponse> logout() => Future.value(_ok('logout'));
  @override Future<bool> isCardReaderConnected() => Future.value(true);
  @override Future<SumupPluginResponse> getSavedCardReaderDetails() => Future.value(_ok('getSavedCardReaderDetails'));
  @override Future<SumupPluginResponse> lastReaderStatus() => Future.value(_ok('lastReaderStatus'));
}

void main() {
  late MockSumupPlatform mockPlatform;

  setUp(() {
    mockPlatform = MockSumupPlatform();
    SumupPlatform.instance = mockPlatform;
  });

  test('SumupPlatform.instance can be set with mock', () {
    expect(SumupPlatform.instance, isA<MockSumupPlatform>());
  });

  test('init sets initialized flag', () async {
    final response = await mockPlatform.init('test-key');
    expect(response.status, isTrue);
    expect(mockPlatform.isInitialized, isTrue);
  });

  test('login returns successful response', () async {
    final response = await mockPlatform.login();
    expect(response.status, isTrue);
  });

  test('checkout returns transaction code', () async {
    final payment = SumupPayment(total: 10.0, currency: 'EUR');
    final request = SumupPaymentRequest(payment);
    final response = await mockPlatform.checkout(request);
    expect(response.transactionCode, equals('TX123'));
  });

  test('isLoggedIn returns true after init', () async {
    await mockPlatform.init('test-key');
    final loggedIn = await mockPlatform.isLoggedIn;
    expect(loggedIn, isTrue);
  });
}
