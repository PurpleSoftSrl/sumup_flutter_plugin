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