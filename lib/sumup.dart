import 'dart:async';

import 'package:flutter/services.dart';

import 'models/sumup_payment_request.dart';
import 'models/sumup_plugin_checkout_response.dart';
import 'models/sumup_plugin_merchant_response.dart';
import 'models/sumup_plugin_response.dart';

export 'models/sumup_payment.dart';
export 'models/sumup_payment_request.dart';
export 'models/sumup_plugin_checkout_response.dart';
export 'models/sumup_plugin_merchant_response.dart';
export 'models/sumup_plugin_response.dart';

class Sumup {
  Sumup._();

  static const MethodChannel _channel = const MethodChannel('sumup');

  static bool _isInitialized = false;

  static void _throwIfNotInitialized() {
    if (!_isInitialized) {
      throw Exception(
          'SumUp SDK is not initialized. You should call Sumup.init(affiliateKey)');
    }
  }

  static Future<void> _throwIfNotLoggedIn() async {
    final isLogged = await isLoggedIn;
    if (isLogged == null || !isLogged) {
      throw Exception('Not logged in. You must login before.');
    }
  }

  /// Initializes SumUp SDK with your [affiliateKey].
  ///
  /// Must be called before anything else
  static Future<SumupPluginResponse> init(String affiliateKey) async {
    final method = await _channel.invokeMethod('initSDK', affiliateKey);
    final response = SumupPluginResponse.fromMap(method);
    if (response.status) {
      _isInitialized = true;
    }
    return response;
  }

  /// Shows SumUp login dialog.
  ///
  /// Should be called after [init].
  static Future<SumupPluginResponse> login() async {
    _throwIfNotInitialized();
    final method = await _channel.invokeMethod('login');
    return SumupPluginResponse.fromMap(method);
  }

  /// Uses Transparent authentication to login to SumUp SDK with supplied token.
  ///
  /// Should be called after [init].
  static Future<SumupPluginResponse> loginWithToken(String token) async {
    _throwIfNotInitialized();
    final method = await _channel.invokeMethod('loginWithToken', token);
    return SumupPluginResponse.fromMap(method);
  }

  /// Returns whether merchant is already logged in.
  static Future<bool?> get isLoggedIn async {
    _throwIfNotInitialized();
    final method = await _channel.invokeMethod('isLoggedIn');
    return SumupPluginResponse.fromMap(method).status;
  }

  /// Returns the current merchant.
  static Future<SumupPluginMerchantResponse> get merchant async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();
    final method = await _channel.invokeMethod('getMerchant');
    final response = SumupPluginResponse.fromMap(method);
    return SumupPluginMerchantResponse.fromMap(response.message!);
  }

  /// Opens SumUp dialog to connect to a card terminal.
  ///
  /// Login required.
  static Future<SumupPluginResponse> openSettings() async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();
    final method = await _channel.invokeMethod('openSettings');
    return SumupPluginResponse.fromMap(method);
  }

  /// Wakes up card terminal before real checkout to speed up bluetooth pairing process.
  ///
  /// Don't call this method during checkout because it can lead to checkout failure.
  /// Login required.
  static Future<SumupPluginResponse> wakeUpTerminal() async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();
    final method = await _channel.invokeMethod('wakeUpTerminal');
    return SumupPluginResponse.fromMap(method);
  }

  /// Calling prepareForCheckout() before instancing a checkout will
  /// speed up the checkout time.
  ///
  /// Don't call this method during checkout because it can lead to checkout failure.
  /// Login required.
  static Future<SumupPluginResponse> prepareForCheckout(
      {bool retainBLEConnection = false}) async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();
    final method =
        await _channel.invokeMethod('prepareForCheckout', retainBLEConnection);
    return SumupPluginResponse.fromMap(method);
  }

  /// Starts a checkout process with [paymentRequest].
  ///
  /// Login required.
  static Future<SumupPluginCheckoutResponse> checkout(
      SumupPaymentRequest paymentRequest) async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();
    final request = paymentRequest.toMap();
    final method = await _channel.invokeMethod('checkout', request);
    final response = SumupPluginResponse.fromMap(method);
    return SumupPluginCheckoutResponse.fromMap(response.message!);
  }

  /// Only available for iOS.
  /// On Android always returns false.
  ///
  /// Login required.
  static Future<bool?> get isCheckoutInProgress async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();
    final method = await _channel.invokeMethod('isCheckoutInProgress');
    return SumupPluginResponse.fromMap(method).status;
  }

  /// Performs logout.
  static Future<SumupPluginResponse> logout() async {
    _throwIfNotInitialized();
    final method = await _channel.invokeMethod('logout');
    return SumupPluginResponse.fromMap(method);
  }
}
