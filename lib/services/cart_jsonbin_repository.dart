import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/cart_item.dart';
import '../models/product.dart';

class CartJsonBinRepository {
  CartJsonBinRepository({http.Client? client}) : _client = client ?? http.Client();

  static const _binId = '6adaabfeffd5d16053843509';
  static const _accessKey = r'$2a$10$06WpFol4mbRCGTD7ilBEy.NgBDv7JsOarjJqwWUx1gdCvaT/o.dti';
  static const _cartKey = 'carrinho';

  final http.Client _client;

  Uri get _uri => Uri.https('api.jsonbin.io', '/v3/b/$_binId');

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Access-Key': _accessKey,
      };

  Future<List<CartItem>> getAll() async {
    final document = await _readDocument();
    final items = document[_cartKey] as List<dynamic>? ?? const [];
    return items
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<CartItem>> addProduct(Product product, int quantity) async {
    if (quantity <= 0) throw Exception('A quantidade precisa ser maior que zero.');
    final items = await getAll();
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) {
      items.add(CartItem(product: product, quantity: quantity));
    } else {
      items[index] = items[index].copyWith(
        product: product,
        quantity: items[index].quantity + quantity,
      );
    }
    await _save(items);
    return items;
  }

  Future<List<CartItem>> updateQuantity(String productId, int quantity) async {
    final items = await getAll();
    final index = items.indexWhere((item) => item.product.id == productId);
    if (index < 0) return items;
    if (quantity <= 0) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: quantity);
    }
    await _save(items);
    return items;
  }

  Future<List<CartItem>> removeProduct(String productId) async {
    final items = await getAll();
    items.removeWhere((item) => item.product.id == productId);
    await _save(items);
    return items;
  }

  Future<List<CartItem>> replaceProduct(Product product) async {
    final items = await getAll();
    final index = items.indexWhere((item) => item.product.id == product.id);
    if (index < 0) return items;
    items[index] = items[index].copyWith(product: product);
    await _save(items);
    return items;
  }

  Future<List<CartItem>> clear() async {
    await _save(const []);
    return const [];
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

  Future<void> _save(List<CartItem> items) async {
    final document = await _readDocument();
    document[_cartKey] = items.map((item) => item.toJson()).toList();
    final response = await _client.put(
      _uri,
      headers: _headers,
      body: jsonEncode(document),
    );
    _check(response);
  }

  void _check(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Falha no JSONBin (HTTP ${response.statusCode}): ${response.body}');
    }
  }
}
