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