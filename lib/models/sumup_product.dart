/// A product item included in a transaction.
///
/// Available on iOS and Android (card reader checkout only).
class SumupProduct {
  SumupProduct({
    this.name,
    this.price,
    this.quantity,
  });

  SumupProduct.fromMap(Map<dynamic, dynamic> map)
      : name = map['name'] as String?,
        price = (map['price'] as num?)?.toDouble(),
        quantity = (map['quantity'] as num?)?.toInt();

  /// Product name.
  final String? name;

  /// Product unit price.
  final double? price;

  /// Product quantity.
  final int? quantity;

  @override
  String toString() => 'SumupProduct(name: $name, price: $price, quantity: $quantity)';
}
