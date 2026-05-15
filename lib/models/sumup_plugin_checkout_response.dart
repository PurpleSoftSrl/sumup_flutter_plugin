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

  SumupPluginCheckoutResponse.fromMap(Map<dynamic, dynamic> response) {
    success = response['success'];
    transactionCode = response['transactionCode'];
    amount = response['amount'];
    currency = response['currency'];
    vatAmount = response['vatAmount'];
    tipAmount = response['tipAmount'];
    paymentType = response['paymentType'];
    entryMode = response['entryMode'];
    installments = int.tryParse(response['installments'].toString());
    cardType = response['cardType'];
    cardLastDigits = response['cardLastDigits'];
    userDismissedSuccessScreen = response['userDismissedSuccessScreen'] as bool?;
    errors = response['errors']?.toString();
    merchantCode = response['merchantCode']?.toString();
    cardScheme = response['cardScheme']?.toString();
    final rawProducts = response['products'];
    if (rawProducts is List) {
      products = rawProducts
          .whereType<Map>()
          .map((e) => SumupProduct.fromMap(e))
          .toList();
    }

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

  String toString() {
    return 'Success: $success, transactionCode: $transactionCode, amount: $amount, currency: $currency${errors != null ? ", errors: $errors" : ""}';
  }
}
