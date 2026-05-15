// ignore_for_file: public_member_api_docs

/// Merchant response object.
///
/// Contains current merchant code and currency code.
class SumupPluginMerchantResponse {
  SumupPluginMerchantResponse({
    this.merchantCode,
    this.currencyCode,
  });

  /// Creates a merchant response from the native channel map.
  SumupPluginMerchantResponse.fromMap(Map<dynamic, dynamic> response) {
    merchantCode = response['merchantCode'] as String?;
    currencyCode = response['currencyCode'] as String?;
  }

  /// Current merchant identification code.
  String? merchantCode;

  /// ISO 4217 currency code of the merchant account (e.g. EUR, USD).
  String? currencyCode;

  @override
  String toString() {
    return 'MerchantCode: $merchantCode, currencyCode: $currencyCode';
  }
}
