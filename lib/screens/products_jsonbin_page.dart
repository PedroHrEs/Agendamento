import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_item.dart';
import '../models/product.dart';
import '../services/cart_jsonbin_repository.dart';
import '../services/product_jsonbin_repository.dart';
import '../utils/currency_formatter.dart';
import 'product_cart_page.dart';

class ProductsJsonBinPage extends StatefulWidget {
  const ProductsJsonBinPage({super.key});

  @override
  State<ProductsJsonBinPage> createState() => _ProductsJsonBinPageState();
}

class _ProductsJsonBinPageState extends State<ProductsJsonBinPage> {
  static const _primary = Color(0xFF007A78);
  final _repository = ProductJsonBinRepository();
  final _cartRepository = CartJsonBinRepository();
  late Future<List<Product>> _products;
  List<CartItem> _cart = [];
  bool _isCartLoading = true;
  bool _isCartSaving = false;
  String _search = '';

  int get _cartCount => _cart.fold(0, (count, item) => count + item.quantity);

  @override
  void initState() {
    super.initState();
    _products = _repository.getAll();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final items = await _cartRepository.getAll();
      if (!mounted) return;
      setState(() {
        _cart = items;
        _isCartLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isCartLoading = false);
      _message('Não foi possível carregar o carrinho: ${_errorText(error)}');
    }
  }

  Future<void> _reload() async {
    final refreshedProducts = await _repository.getAll();
    if (!mounted) return;
    setState(() {
      _products = Future.value(refreshedProducts);
    });
  }

  Future<void> _openForm([Product? product]) async {
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => _ProductFormDialog(product: product),
    );
    if (result == null || !mounted) return;
    try {
      if (product == null) {
        await _repository.create(result);
      } else {
        await _repository.update(result);
        await _updateCartProduct(result);
      }
      await _reload();
      if (mounted) _message(product == null ? 'Produto cadastrado.' : 'Produto atualizado.');
    } catch (error) {
      if (mounted) _message(_errorText(error));
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir produto?'),
        content: Text('O produto "${product.descricao}" será removido.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Excluir')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.delete(product.id);
      await _removeFromCart(product.id);
      await _reload();
      if (mounted) _message('Produto excluído.');
    } catch (error) {
      if (mounted) _message(_errorText(error));
    }
  }

  Future<void> _chooseQuantity(Product product) async {
    final selectedQuantity = await showDialog<int>(
      context: context,
      builder: (_) => _QuantityPickerDialog(product: product),
    );
    if (selectedQuantity == null || !mounted) return;
    await _addToCart(product, selectedQuantity);
  }

  Future<void> _addToCart(Product product, int quantity) async {
    if (_isCartLoading || _isCartSaving) return;
    setState(() => _isCartSaving = true);
    try {
      final items = await _cartRepository.addProduct(product, quantity);
      if (!mounted) return;
      setState(() => _cart = items);
      _message('$quantity unidade(s) de ${product.descricao} adicionada(s) ao carrinho.');
    } catch (error) {
      if (mounted) _message(_errorText(error));
    } finally {
      if (mounted) setState(() => _isCartSaving = false);
    }
  }

  Future<void> _updateCartProduct(Product product) async {
    if (!_cart.any((item) => item.product.id == product.id)) return;
    final items = await _cartRepository.replaceProduct(product);
    if (mounted) setState(() => _cart = items);
  }

  Future<void> _removeFromCart(String productId) async {
    if (!_cart.any((item) => item.product.id == productId)) return;
    final items = await _cartRepository.removeProduct(productId);
    if (mounted) setState(() => _cart = items);
  }

  void _openCart() {
    if (_isCartLoading || _isCartSaving) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ProductCartPage(
          initialItems: _cart,
          repository: _cartRepository,
          onChanged: (items) {
            if (!mounted) return;
            setState(() => _cart = items);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Produtos'),
          actions: [
            IconButton(
              tooltip: 'Carrinho ($_cartCount itens)',
              onPressed: _isCartLoading || _isCartSaving ? null : _openCart,
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.shopping_cart_outlined),
                  if (_cartCount > 0)
                    Positioned(
                      right: -8,
                      top: -8,
                      child: Container(
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            _cartCount > 99 ? '99+' : '$_cartCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openForm(),
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('Cadastrar'),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                labelText: 'Consultar produtos',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: _products,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) return _errorView(snapshot.error!);
                final allProducts = snapshot.data ?? const <Product>[];
                final query = _search.trim().toLowerCase();
                final products = allProducts
                    .where((item) => item.descricao.toLowerCase().contains(query))
                    .toList();
                if (products.isEmpty) {
                  return Center(
                    child: Text(allProducts.isEmpty
                        ? 'Nenhum produto cadastrado.'
                        : 'Nenhum produto encontrado.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return Card(
                      child: ListTile(
                        leading: _image(product.imagem),
                        title: Text(product.descricao),
                        subtitle: Text(formatBrazilianCurrency(product.valor)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: 'Adicionar ao carrinho',
                              onPressed: _isCartLoading || _isCartSaving
                                  ? null
                                  : () => _chooseQuantity(product),
                              icon: const Icon(Icons.add_shopping_cart),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (action) => action == 'edit'
                                  ? _openForm(product)
                                  : _delete(product),
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Alterar')),
                                PopupMenuItem(value: 'delete', child: Text('Excluir')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ]),
      );

  Widget _image(String url) => ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          url,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 56,
            height: 56,
            color: const Color(0xFFE3F3F1),
            child: const Icon(Icons.image_not_supported_outlined, color: _primary),
          ),
        ),
      );

  Widget _errorView(Object error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.cloud_off_outlined, size: 40, color: _primary),
            const SizedBox(height: 12),
            Text(_errorText(error), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _retryLoad,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ]),
        ),
      );

  void _retryLoad() {
    setState(() {
      _products = _repository.getAll();
    });
  }

  String _errorText(Object error) => error.toString().replaceFirst('Exception: ', '');

  void _message(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _QuantityPickerDialog extends StatefulWidget {
  const _QuantityPickerDialog({required this.product});

  final Product product;

  @override
  State<_QuantityPickerDialog> createState() => _QuantityPickerDialogState();
}

class _QuantityPickerDialogState extends State<_QuantityPickerDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _quantity;

  @override
  void initState() {
    super.initState();
    _quantity = TextEditingController(text: '1');
  }

  @override
  void dispose() {
    _quantity.dispose();
    super.dispose();
  }

  void _adjustQuantity(int adjustment) {
    final current = int.tryParse(_quantity.text) ?? 1;
    final next = (current + adjustment).clamp(1, 999999);
    _quantity.value = TextEditingValue(
      text: '$next',
      selection: TextSelection.collapsed(offset: '$next'.length),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Adicionar ao carrinho'),
        content: SizedBox(
          width: 340,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.product.descricao),
                const SizedBox(height: 16),
                Row(
                  children: [
                    IconButton(
                      tooltip: 'Diminuir quantidade',
                      onPressed: () => _adjustQuantity(-1),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _quantity,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        decoration: const InputDecoration(
                          labelText: 'Quantidade',
                          counterText: '',
                        ),
                        validator: (value) {
                          final quantity = int.tryParse(value ?? '');
                          if (quantity == null || quantity <= 0) {
                            return 'Informe pelo menos 1.';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Aumentar quantidade',
                      onPressed: () => _adjustQuantity(1),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, int.parse(_quantity.text));
            },
            child: const Text('Adicionar'),
          ),
        ],
      );
}

class _ProductFormDialog extends StatefulWidget {
  const _ProductFormDialog({this.product});

  final Product? product;

  @override
  State<_ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<_ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descricao;
  late final TextEditingController _valor;
  late final TextEditingController _imagem;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _descricao = TextEditingController(text: product?.descricao);
    _valor = TextEditingController(
      text: product?.valor.toStringAsFixed(2).replaceAll('.', ','),
    );
    _imagem = TextEditingController(text: product?.imagem);
  }

  @override
  void dispose() {
    _descricao.dispose();
    _valor.dispose();
    _imagem.dispose();
    super.dispose();
  }

  double? get _parsedValue =>
      double.tryParse(_valor.text.trim().replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.product == null ? 'Cadastrar produto' : 'Alterar produto'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _field(_descricao, 'Descrição'),
                _field(_valor, 'Valor', keyboard: const TextInputType.numberWithOptions(decimal: true)),
                _field(_imagem, 'URL da imagem', keyboard: TextInputType.url),
              ]),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(
                context,
                Product(
                  id: widget.product?.id ?? '',
                  descricao: _descricao.text.trim(),
                  valor: _parsedValue!,
                  imagem: _imagem.text.trim(),
                ),
              );
            },
            child: const Text('Salvar'),
          ),
        ],
      );

  Widget _field(TextEditingController controller, String label,
          {TextInputType? keyboard}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          keyboardType: keyboard,
          decoration: InputDecoration(
            labelText: label,
            prefixText: label == 'Valor' ? 'R\$ ' : null,
          ),
          validator: (value) {
            final text = value?.trim() ?? '';
            if (text.isEmpty) return 'Informe $label.';
            if (label == 'Descrição' && text.runes.length <= 3) {
              return 'A descrição deve ter mais de 3 caracteres.';
            }
            if (label == 'Valor') {
              final parsed = double.tryParse(text.replaceAll(',', '.'));
              if (parsed == null || !parsed.isFinite || parsed <= 0) {
                return 'Informe um valor maior que zero.';
              }
            }
            if (label == 'URL da imagem') {
              final uri = Uri.tryParse(text);
              if (uri == null || !uri.hasAuthority ||
                  (uri.scheme != 'http' && uri.scheme != 'https')) {
                return 'Informe uma URL válida (http ou https).';
              }
            }
            return null;
          },
        ),
      );
}
