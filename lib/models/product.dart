class Product {
  const Product({
    required this.id,
    required this.descricao,
    required this.valor,
    required this.imagem,
  });

  final String id;
  final String descricao;
  final double valor;
  final String imagem;

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id']?.toString() ?? '',
        descricao: json['descricao'] as String? ?? '',
        valor: _parseValor(json['valor']),
        imagem: json['imagem'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'descricao': descricao.trim(),
        'valor': valor,
        'imagem': imagem.trim(),
      };

  static double _parseValor(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
