import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class Sumup {
  static const MethodChannel _channel = const MethodChannel('sumup');

  /// Initializes Sumup SDK with your [affiliateKey]
  ///
  /// Must be called before anything else
  static Future<SumupPluginResponse> init(String affiliateKey) async {
    return SumupPluginResponse.fromMap(await _channel.invokeMethod('initSDK', affiliateKey));
  }

  /// Should be called after [init]
  static Future<SumupPluginResponse> login() async {
    return SumupPluginResponse.fromMap(await _channel.invokeMethod('login'));
  }

  static Future<bool> get isLoggedIn async {
    return SumupPluginResponse.fromMap(await _channel.invokeMethod('isLoggedIn')).status;
  }

  /// Returns the current merchant
  static Future<SumupPluginMerchantResponse> get merchant async {
    var response = SumupPluginResponse.fromMap(await _channel.invokeMethod('getMerchant'));

    return SumupPluginMerchantResponse.fromMap(response.message);
  }

  /// Sets up card terminal
  ///
  /// Login required
  static Future<SumupPluginResponse> openSettings() async {
    return SumupPluginResponse.fromMap(await _channel.invokeMethod('openSettings'));
  }

  /// Starts a checkout process with [paymentRequest]
  ///
  /// Login required
  static Future<SumupPluginCheckoutResponse> checkout(SumupPaymentRequest paymentRequest) async {
    var response = SumupPluginResponse.fromMap(
        await _channel.invokeMethod('checkout', paymentRequest.toMap()));

    return SumupPluginCheckoutResponse.fromMap(response.message);
  }

  /// Only available for iOS
  ///
  /// Login required
  static Future<bool> get isCheckoutInProgress async {
    return SumupPluginResponse.fromMap(await _channel.invokeMethod('isCheckoutInProgress')).status;
  }

  static Future<SumupPluginResponse> logout() async {
    return SumupPluginResponse.fromMap(await _channel.invokeMethod('logout'));
  }
}

/// Sumup payment request
class SumupPaymentRequest {
  SumupPaymentRequest(this.payment, {this.info});

  SumupPayment payment;
  Map<String, String> info;

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
    this.foreignTransactionID,
    this.saleItemsCount = 0,
  });

  double total, tip;
  String title, currency, foreignTransactionID;
  bool skipSuccessScreen;
  int saleItemsCount;

  Map<String, dynamic> toMap() => {
        'total': total,
        'title': title,
        'currency': currency,
        'tip': tip,
        'skipSuccessScreen': skipSuccessScreen,
        'foreignTransactionID': foreignTransactionID,
        'saleItemsCount': saleItemsCount,
      };
}

/// Response returned from native platform
class SumupPluginResponse {
  SumupPluginResponse({
    this.methodName,
    this.status,
    this.message,
  });

  String methodName;
  bool status;
  Map<dynamic, dynamic> message;

  SumupPluginResponse.fromMap(Map<dynamic, dynamic> response) {
    methodName = response['methodName'];
    status = response['status'];
    message = response['message'];
  }

  String toString() {
    return 'Method: $methodName, status: $status, message: $message';
  }
}

// TODO add products field
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

  String transactionCode;
  bool success;
  String cardLastDigits;
  String cardType;
  double amount;
  double vatAmount;
  double tipAmount;
  String currency;
  String paymentType;
  String entryMode;
  int installments;

  // Android only
  bool receiptSent;
  String foreignTransactionId;

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

  String toString() {
    return 'Success: $success, transactionCode: $transactionCode, amount: $amount, currency: $currency';
  }
}

class SumupPluginMerchantResponse {
  SumupPluginMerchantResponse({this.merchantCode, this.currencyCode});

  String merchantCode;
  String currencyCode;

  SumupPluginMerchantResponse.fromMap(Map<dynamic, dynamic> response) {
    merchantCode = response['merchantCode'];
    currencyCode = response['currencyCode'];
  }

  String toString() {
    return 'MerchantCode: $merchantCode, currencyCode: $currencyCode';
  }
}
