// ignore_for_file: public_member_api_docs

/// A product item in a checkout or transaction.
class SumupProduct {
  SumupProduct({
    this.name,
    this.price,
    this.quantity,
  });

  /// Deserializes a product from a map (native platform bridge).
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
