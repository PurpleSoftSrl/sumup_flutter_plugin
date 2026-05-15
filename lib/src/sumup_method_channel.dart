import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/sumup_payment_request.dart';
import '../models/sumup_plugin_checkout_response.dart';
import '../models/sumup_plugin_merchant_response.dart';
import '../models/sumup_plugin_response.dart';
import '../models/tap_to_pay_availability.dart';
import 'sumup_platform_interface.dart';

/// Default [SumupPlatform] implementation using [MethodChannel] for native communication.

class MethodChannelSumup extends SumupPlatform {
  /// The method channel used for native communication (visible for testing).
  @visibleForTesting
  static const methodChannel = MethodChannel('sumup');

  Future<SumupPluginResponse> _invoke(String method, [dynamic arguments]) async {
    try {
      final result = await methodChannel.invokeMethod<Map<dynamic, dynamic>>(method, arguments);
      return SumupPluginResponse.fromMap(result ?? {});
    } on PlatformException catch (e) {
      return SumupPluginResponse.fromMap(<dynamic, dynamic>{
        'methodName': method,
        'status': false,
        'message': <dynamic, dynamic>{'errors': e.message ?? 'Native platform error'},
      });
    }
  }

  Future<bool> _invokeStatus(String method, [dynamic arguments]) async {
    final response = await _invoke(method, arguments);
    return response.status;
  }

  Future<T> _invokeMapped<T>(
    String method, {
    dynamic arguments,
    required T Function(Map<dynamic, dynamic>) mapper,
  }) async {
    final response = await _invoke(method, arguments);
    final message = response.message ?? <String, dynamic>{};
    return mapper(message);
  }

  @override
  Future<SumupPluginResponse> init(String affiliateKey) async {
    final response = await _invoke('initSDK', affiliateKey);
    if (response.status) isInitialized = true;
    return response;
  }

  @override
  Future<SumupPluginResponse> login() => _invoke('login');

  @override
  Future<SumupPluginResponse> loginWithToken(String token) => _invoke('loginWithToken', token);

  @override
  Future<bool?> get isLoggedIn => _invokeStatus('isLoggedIn');

  @override
  Future<SumupPluginMerchantResponse> get merchant =>
      _invokeMapped('getMerchant', mapper: SumupPluginMerchantResponse.fromMap);

  @override
  Future<SumupPluginResponse> openSettings() => _invoke('openSettings');

  @override
  Future<SumupPluginResponse> prepareForCheckout() => _invoke('prepareForCheckout');

  @override
  Future<bool> get isTipOnCardReaderAvailable => _invokeStatus('isTipOnCardReaderAvailable');

  @override
  Future<bool> get isCardTypeRequired => _invokeStatus('isCardTypeRequired');

  @override
  Future<TapToPayAvailabilityResult> checkTapToPayAvailability() =>
      _invokeMapped('checkTapToPayAvailability', mapper: TapToPayAvailabilityResult.fromMap);

  @override
  Future<SumupPluginResponse> presentTapToPayActivation() => _invoke('presentTapToPayActivation');

  @override
  Future<SumupPluginCheckoutResponse> checkout(SumupPaymentRequest paymentRequest) =>
      _invokeMapped('checkout', arguments: paymentRequest.toMap(), mapper: SumupPluginCheckoutResponse.fromMap);

  @override
  Future<bool?> get isCheckoutInProgress => _invokeStatus('isCheckoutInProgress');

  @override
  Future<SumupPluginResponse> logout() => _invoke('logout');

  @override
  Future<bool> isCardReaderConnected() async {
    final response = await _invoke('isCardReaderConnected');
    return response.message?['connected'] == true;
  }

  @override
  Future<SumupPluginResponse> getSavedCardReaderDetails() => _invoke('getSavedCardReaderDetails');

  @override
  Future<SumupPluginResponse> lastReaderStatus() => _invoke('lastReaderStatus');
}
