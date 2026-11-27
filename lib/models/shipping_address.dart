class ShippingAddress {
  const ShippingAddress({
    required this.cep,
    required this.street,
    required this.neighborhood,
    required this.city,
    required this.state,
  });

  final String cep;
  final String street;
  final String neighborhood;
  final String city;
  final String state;

  String get locality => '$city - $state';

  factory ShippingAddress.fromJson(Map<String, dynamic> json) =>
      ShippingAddress(
        cep: json['cep'] as String? ?? '',
        street: json['logradouro'] as String? ?? '',
        neighborhood: json['bairro'] as String? ?? '',
        city: json['localidade'] as String? ?? '',
        state: json['uf'] as String? ?? '',
      );
}
