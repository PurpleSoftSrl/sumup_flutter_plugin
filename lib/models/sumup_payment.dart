/// Payment object.
class SumupPayment {
  SumupPayment({
    this.title,
    required this.total,
    this.currency = 'EUR',
    this.tip = .0,
    this.tipOnCardReader = false,
    this.skipSuccessScreen = false,
    this.skipFailureScreen = false,
    this.foreignTransactionId,
    this.saleItemsCount = 0,
    this.customerEmail,
    this.customerPhone,
    this.cardType,
  }) : assert(!tipOnCardReader || tip == 0,
            'If [tipOnCardReader] is true, [tip] must be zero. The two options are mutually exclusive.');

  /// Total payment amount.
  double total;

  /// Optional tip, defaults to 0. If tip is grater than 0, [tipOnCardReader] must be false.
  double tip;

  /// Shows tip on card reader if card reader supports it. If tipOnCardReader is true, [tip] must be 0.
  bool tipOnCardReader;

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

  /// Optional card type that in some country is required.
  /// 
  /// Call [Sumup.isCardTypeRequired] to check if card type is required in checkout.
  ///
  /// iOS only
  CardType? cardType;

  Map<String, dynamic> toMap() => {
        'total': total,
        'title': title,
        'currency': currency.toUpperCase(),
        'tip': tip,
        'tipOnCardReader': tipOnCardReader,
        'skipSuccessScreen': skipSuccessScreen,
        'skipFailureScreen': skipFailureScreen,
        'foreignTransactionId': foreignTransactionId,
        'saleItemsCount': saleItemsCount,
        'customerEmail': customerEmail,
        'customerPhone': customerPhone,
        'cardType': cardType?.name,
      };
}

enum CardType {
  debit,
  credit,
}
