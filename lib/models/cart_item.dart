import 'product.dart';

class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get subtotal => product.valor * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        product: Product.fromJson(json['produto'] as Map<String, dynamic>),
        quantity: (json['quantidade'] as num?)?.toInt() ?? 1,
      );

  Map<String, dynamic> toJson() => {
        'produto': product.toJson(),
        'quantidade': quantity,
      };

  CartItem copyWith({Product? product, int? quantity}) => CartItem(
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
      );
}
