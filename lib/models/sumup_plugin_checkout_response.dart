import 'dart:io';

// TODO add products field

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
  });

  SumupPluginCheckoutResponse.fromMap(Map<dynamic, dynamic> response) {
    success = response['success'];
    if (response['transactionCode'] != '')
      transactionCode = response['transactionCode'];
    if (response['amount'] != '')
      amount = response['amount'];
    if (response['currency'] != '')
      currency = response['currency'];
    if (response['vatAmount'] != '')
      vatAmount = response['vatAmount'];
    if (response['tipAmount'] != '')
      tipAmount = response['tipAmount'];
    if (response['paymentType'] != '')
      paymentType = response['paymentType'];
    if (response['entryMode'] != '')
      entryMode = response['entryMode'];
    if (response['installments'] != '')
      installments = response['installments'];
    if (response['cardType'] != '')
      cardType = response['cardType'];
    if (response['cardLastDigits'] != '')
      cardLastDigits = response['cardLastDigits'];
    //products = response['products'];

    // some parameters are available only for Android
    if (Platform.isAndroid) {
      if (response['foreignTransactionId'] != '')
        foreignTransactionId = response['foreignTransactionId'];
      if (response['receiptSent'] != '')
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
