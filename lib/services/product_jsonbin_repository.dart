import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductJsonBinRepository {
  ProductJsonBinRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _binId = '6adaabfeffd5d16053843509';
  static const _accessKey = r'$2a$10$06WpFol4mbRCGTD7ilBEy.NgBDv7JsOarjJqwWUx1gdCvaT/o.dti';
  static const _productsKey = 'produtos';

  final http.Client _client;

  Uri get _uri => Uri.https('api.jsonbin.io', '/v3/b/$_binId');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Access-Key': _accessKey,
      };

  Future<List<Product>> getAll() async {
    final document = await _readDocument();
    final products = document[_productsKey] as List<dynamic>? ?? const [];
    return products
        .map((item) => Product.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> create(Product product) async {
    _validate(product);
    final products = await getAll();
    final id = _newId();
    await _save([...products, Product(
      id: id,
      descricao: product.descricao,
      valor: product.valor,
      imagem: product.imagem,
    )]);
  }

  Future<void> update(Product product) async {
    _validate(product);
    final products = await getAll();
    final index = products.indexWhere((item) => item.id == product.id);
    if (index < 0) throw Exception('Produto não encontrado. Atualize a lista e tente novamente.');
    products[index] = product;
    await _save(products);
  }

  Future<void> delete(String id) async {
    final products = await getAll();
    products.removeWhere((item) => item.id == id);
    await _save(products);
  }

  Future<Map<String, dynamic>> _readDocument() async {
    final response = await _client.get(
      _uri.replace(path: '${_uri.path}/latest'),
      headers: _headers,
    );
    _check(response);
    final root = jsonDecode(response.body) as Map<String, dynamic>;
    return Map<String, dynamic>.from(root['record'] as Map<String, dynamic>? ?? root);
  }

  Future<void> _save(List<Product> products) async {
    final document = await _readDocument();
    document[_productsKey] = products.map((item) => item.toJson()).toList();
    final response = await _client.put(
      _uri,
      headers: _headers,
      body: jsonEncode(document),
    );
    _check(response);
  }

  void _validate(Product product) {
    if (product.descricao.trim().runes.length <= 3) {
      throw Exception('A descrição deve ter mais de 3 caracteres.');
    }
    if (!product.valor.isFinite || product.valor <= 0) {
      throw Exception('Informe um valor maior que zero.');
    }
    final imageUrl = product.imagem.trim();
    if (imageUrl.isEmpty) {
      throw Exception('Informe a URL da imagem.');
    }
    final uri = Uri.tryParse(imageUrl);
    if (uri == null || !uri.hasAuthority ||
        (uri.scheme != 'http' && uri.scheme != 'https')) {
      throw Exception('Informe uma URL de imagem válida (http ou https).');
    }
  }

  String _newId() {
    final random = Random.secure();
    // Keep the bound below 2^31: bit shifts to 32 bits become zero on Flutter Web.
    return '${DateTime.now().microsecondsSinceEpoch}-${random.nextInt(2147483647)}';
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha no JSONBin (HTTP ${response.statusCode}): ${response.body}');
    }
  }
}
