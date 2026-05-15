// ignore_for_file: public_member_api_docs
import 'dart:io';

import 'sumup_product.dart';

/// Checkout response object.
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
    this.userDismissedSuccessScreen,
    this.errors,
    this.products,
    this.merchantCode,
    this.cardScheme,
  });

  /// Deserializes a checkout response from a map (native platform bridge).
  /// Creates a checkout response from the native channel map.
  SumupPluginCheckoutResponse.fromMap(Map<dynamic, dynamic> response) {
    success = response['success'] as bool?;
    transactionCode = response['transactionCode'] as String?;
    amount = _toDouble(response['amount']);
    currency = response['currency'] as String?;
    vatAmount = _toDouble(response['vatAmount']);
    tipAmount = _toDouble(response['tipAmount']);
    paymentType = response['paymentType'] as String?;
    entryMode = response['entryMode'] as String?;
    installments = _toInt(response['installments']);
    cardType = response['cardType'] as String?;
    cardLastDigits = response['cardLastDigits'] as String?;
    userDismissedSuccessScreen = response['userDismissedSuccessScreen'] as bool?;
    errors = response['errors']?.toString();
    merchantCode = response['merchantCode']?.toString();
    cardScheme = response['cardScheme']?.toString();
    final rawProducts = response['products'];
    if (rawProducts is List) {
      products = rawProducts
          .whereType<Map<dynamic, dynamic>>()
          .map((e) => SumupProduct.fromMap(e))
          .toList();
    }

    if (Platform.isAndroid) {
      foreignTransactionId = response['foreignTransactionId'] as String?;
      receiptSent = response['receiptSent'] as bool?;
    }
  }

  /// Converts a dynamic value to [double], handling null, int, and String types.
  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Converts a dynamic value to [int], handling null and String types.
  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Transaction's outcome
  bool? success;

  /// Unique transaction identifier.
  String? transactionCode;

  /// Last 4 digits of the card used (card reader only).
  String? cardLastDigits;

  /// Card type (e.g. VISA, MASTERCARD).
  String? cardType;

  /// Total amount including tip and VAT
  double? amount;

  /// VAT amount included in the transaction.
  double? vatAmount;

  /// Tip amount included in the transaction.
  double? tipAmount;

  /// ISO 4217 currency code (e.g. EUR, USD).
  String? currency;

  /// Payment method (e.g. CARD, CASH).
  String? paymentType;

  /// Card entry mode (e.g. EMV, MAGSTRIPE).
  String? entryMode;

  /// Number of installments (Android only).
  int? installments;

  /// **Android only**
  bool? receiptSent;

  /// **Android only**
  String? foreignTransactionId;

  /// Merchant code associated with the transaction (Android Tap-to-Pay).
  String? merchantCode;

  /// Card scheme (e.g. VISA, MASTERCARD) (Android Tap-to-Pay).
  String? cardScheme;

  /// True when the user closed the success screen (e.g. back arrow) instead of Done/Send receipt.
  bool? userDismissedSuccessScreen;

  /// Error message when [success] is false (e.g. "Transaction canceled", "Tap-to-Pay init failed").
  String? errors;

  /// Products included in the transaction.
  ///
  /// Available on iOS and Android (card reader only; not available for Tap-to-Pay).
  List<SumupProduct>? products;

  @override
  String toString() {
    return 'Success: $success, transactionCode: $transactionCode, amount: $amount, currency: $currency${errors != null ? ", errors: $errors" : ""}';
  }
}
