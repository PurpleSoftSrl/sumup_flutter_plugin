import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class Sumup {
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

  /// Initializes Sumup SDK with your [affiliateKey]
  ///
  /// Must be called before anything else
  static Future<SumupPluginResponse> init(String affiliateKey) async {
    final response = SumupPluginResponse.fromMap(
        await _channel.invokeMethod('initSDK', affiliateKey));
    if (response.status) {
      _isInitialized = true;
    }
    return response;
  }

  /// Should be called after [init]
  static Future<SumupPluginResponse> login() async {
    _throwIfNotInitialized();
    return SumupPluginResponse.fromMap(await _channel.invokeMethod('login'));
  }

  static Future<bool?> get isLoggedIn async {
    _throwIfNotInitialized();
    return SumupPluginResponse.fromMap(
            await _channel.invokeMethod('isLoggedIn'))
        .status;
  }

  /// Returns the current merchant
  static Future<SumupPluginMerchantResponse> get merchant async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();

    final response =
        SumupPluginResponse.fromMap(await _channel.invokeMethod('getMerchant'));
    return SumupPluginMerchantResponse.fromMap(response.message!);
  }

  /// Sets up card terminal
  ///
  /// Login required
  static Future<SumupPluginResponse> openSettings() async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();

    return SumupPluginResponse.fromMap(
        await _channel.invokeMethod('openSettings'));
  }

  /// Wakes up card terminal before real checkout to speed up bluetooth pairing process
  ///
  /// Login required
  static Future<SumupPluginResponse> wakeUpTerminal() async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();

    return SumupPluginResponse.fromMap(
        await _channel.invokeMethod('wakeUpTerminal'));
  }

  /// Starts a checkout process with [paymentRequest]
  ///
  /// Login required
  static Future<SumupPluginCheckoutResponse> checkout(
      SumupPaymentRequest paymentRequest) async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();

    final response = SumupPluginResponse.fromMap(
        await _channel.invokeMethod('checkout', paymentRequest.toMap()));

    return SumupPluginCheckoutResponse.fromMap(response.message!);
  }

  /// Only available for iOS.
  /// On Android always returns false.
  ///
  /// Login required
  static Future<bool?> get isCheckoutInProgress async {
    _throwIfNotInitialized();
    await _throwIfNotLoggedIn();

    final response = SumupPluginResponse.fromMap(
            await _channel.invokeMethod('isCheckoutInProgress'))
        .status;

    return response;
  }

  static Future<SumupPluginResponse> logout() async {
    _throwIfNotInitialized();

    return SumupPluginResponse.fromMap(await _channel.invokeMethod('logout'));
  }
}

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

/// Sumup payment
class SumupPayment {
  SumupPayment({
    this.title,
    this.total,
    this.currency = 'EUR',
    this.tip = .0,
    this.skipSuccessScreen = false,
    this.foreignTransactionId,
    this.saleItemsCount = 0,
  });

  double? total, tip;

  String? title, currency;

  /// An identifier associated with the transaction that can be used to retrieve details related to the transaction
  String? foreignTransactionId;

  /// Skips success screen. Useful if you want to provide your own success message.
  bool skipSuccessScreen;

  int saleItemsCount;

  Map<String, dynamic> toMap() => {
        'total': total,
        'title': title,
        'currency': currency,
        'tip': tip,
        'skipSuccessScreen': skipSuccessScreen,
        'foreignTransactionId': foreignTransactionId,
        'saleItemsCount': saleItemsCount,
      };
}

/// Response returned from native platform
class SumupPluginResponse {
  SumupPluginResponse.fromMap(Map<dynamic, dynamic> response)
      : methodName = response['methodName'],
        status = response['status'],
        message = response['message'];

  String methodName;
  bool status;
  Map<dynamic, dynamic>? message;

  String toString() {
    return 'Method: $methodName, status: $status, message: $message';
  }
}

// TODO add products field
/// Checkout response object
///
/// Contains all the transaction informations.
/// Some fields are available for Android only.
class SumupPluginCheckoutResponse {
  SumupPluginCheckoutResponse({
    this.success,
    this.transactionCode,
    this.cardLastDigits,
    this.cardType,
    this.receiptSent,
    this.foreignTransactionId,
    this.amount,
    this.vatAmount,
    this.tipAmount,
    this.currency,
    this.paymentType,
    this.entryMode,
    this.installments,
  });

  SumupPluginCheckoutResponse.fromMap(Map<dynamic, dynamic> response) {
    success = response['success'];
    transactionCode = response['transactionCode'];
    amount = response['amount'];
    currency = response['currency'];
    vatAmount = response['vatAmount'];
    tipAmount = response['tipAmount'];
    paymentType = response['paymentType'];
    entryMode = response['entryMode'];
    installments = response['installments'];
    cardType = response['cardType'];
    cardLastDigits = response['cardLastDigits'];
    //products = response['products'];

    // some parameters are available only for Android
    if (Platform.isAndroid) {
      foreignTransactionId = response['foreignTransactionId'];
      receiptSent = response['receiptSent'];
    }
  }

  /// Transaction's outcome
  bool? success;

  String? transactionCode;
  String? cardLastDigits;
  String? cardType;

  /// Total amount including tip and VAT
  double? amount;

  double? vatAmount;
  double? tipAmount;
  String? currency;
  String? paymentType;
  String? entryMode;
  int? installments;

  /// **Android only**
  bool? receiptSent;

  /// **Android only**
  String? foreignTransactionId;

  String toString() {
    return 'Success: $success, transactionCode: $transactionCode, amount: $amount, currency: $currency';
  }
}

/// Merchant response object.
///
/// Contains current merchant code and currency code.
class SumupPluginMerchantResponse {
  SumupPluginMerchantResponse({
    this.merchantCode,
    this.currencyCode,
  });

  SumupPluginMerchantResponse.fromMap(Map<dynamic, dynamic> response) {
    merchantCode = response['merchantCode'];
    currencyCode = response['currencyCode'];
  }

  String? merchantCode;
  String? currencyCode;

  String toString() {
    return 'MerchantCode: $merchantCode, currencyCode: $currencyCode';
  }
}
