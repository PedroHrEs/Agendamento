import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/shipping_address.dart';

class ShippingQuote {
  const ShippingQuote({required this.price, required this.estimatedDays});

  final double price;
  final int estimatedDays;
}

/// Looks up Brazilian addresses and estimates shipping by destination region.
/// Replace [quoteFor] with a carrier integration when one becomes available.
class ShippingQuoteService {
  ShippingQuoteService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<ShippingAddress> lookupPostalCode(String postalCode) async {
    final digits = postalCode.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      throw Exception('Informe um CEP válido com 8 números.');
    }

    final response = await _client.get(
      Uri.https('viacep.com.br', '/ws/$digits/json/'),
    );
    if (response.statusCode != 200) {
      throw Exception('Não foi possível consultar o CEP. Tente novamente.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['erro'] == true) throw Exception('CEP não encontrado.');

    final address = ShippingAddress.fromJson(data);
    if (address.city.isEmpty || address.state.isEmpty) {
      throw Exception('O CEP não retornou uma localidade completa.');
    }
    return address;
  }

  ShippingQuote quoteFor(ShippingAddress address) {
    switch (address.state.toUpperCase()) {
      case 'SP':
        return const ShippingQuote(price: 12.90, estimatedDays: 3);
      case 'RJ':
      case 'MG':
      case 'ES':
        return const ShippingQuote(price: 18.90, estimatedDays: 5);
      case 'PR':
      case 'SC':
      case 'RS':
        return const ShippingQuote(price: 22.90, estimatedDays: 6);
      case 'DF':
      case 'GO':
      case 'MT':
      case 'MS':
        return const ShippingQuote(price: 27.90, estimatedDays: 8);
      case 'AL':
      case 'BA':
      case 'CE':
      case 'MA':
      case 'PB':
      case 'PE':
      case 'PI':
      case 'RN':
      case 'SE':
        return const ShippingQuote(price: 32.90, estimatedDays: 10);
      case 'AC':
      case 'AP':
      case 'AM':
      case 'PA':
      case 'RO':
      case 'RR':
      case 'TO':
        return const ShippingQuote(price: 39.90, estimatedDays: 12);
      default:
        throw Exception('Não foi possível calcular o frete para esse estado.');
    }
  }
}
