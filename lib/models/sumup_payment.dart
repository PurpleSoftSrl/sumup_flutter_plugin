/// Payment object.
class SumupPayment {
  SumupPayment({
    this.title,
    required this.total,
    this.currency = 'EUR',
    this.tip = .0,
    this.skipSuccessScreen = false,
    this.skipFailureScreen = false,
    this.foreignTransactionId,
    this.saleItemsCount = 0,
    this.customerEmail,
    this.customerPhone,
  });

  /// Total payment amount.
  double total;

  /// Optional tip, defaults to 0.
  double tip;

  /// Optional payment title, will be visible on merchant transaction history.
  String? title;

  /// Payment currency, defaults to EUR.
  String currency;

  /// An identifier associated with the transaction that can be used to retrieve details related to the transaction.
  String? foreignTransactionId;

  /// Skips success screen. Useful if you want to provide your own success message.
  bool skipSuccessScreen;

  /// Skips failure screen. Useful if you want to provide your own failure message.
  bool skipFailureScreen;

  /// Number of items included in this payment, visible in SumUp checkout screen.
  int saleItemsCount;

  /// Optional customer email useful to autofill email field on transaction successful screen.
  ///
  /// Android only (see https://github.com/sumup/sumup-ios-sdk/issues/74)
  String? customerEmail;

  /// Optional customer phone number useful to autofill phone field on transaction successful screen.
  ///
  /// Android only (see https://github.com/sumup/sumup-ios-sdk/issues/74)
  String? customerPhone;

  Map<String, dynamic> toMap() => {
        'total': total,
        'title': title,
        'currency': currency,
        'tip': tip,
        'skipSuccessScreen': skipSuccessScreen,
        'skipFailureScreen': skipFailureScreen,
        'foreignTransactionId': foreignTransactionId,
        'saleItemsCount': saleItemsCount,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
      };
}
