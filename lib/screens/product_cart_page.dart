import 'package:flutter/material.dart';

import '../models/cart_item.dart';
import '../services/cart_jsonbin_repository.dart';
import '../utils/currency_formatter.dart';

class ProductCartPage extends StatefulWidget {
  const ProductCartPage({
    required this.initialItems,
    required this.repository,
    required this.onChanged,
    super.key,
  });

  final List<CartItem> initialItems;
  final CartJsonBinRepository repository;
  final ValueChanged<List<CartItem>> onChanged;

  @override
  State<ProductCartPage> createState() => _ProductCartPageState();
}

class _ProductCartPageState extends State<ProductCartPage> {
  static const _primary = Color(0xFF007A78);
  late List<CartItem> _items;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List<CartItem>.of(widget.initialItems);
  }

  double get _total =>
      _items.fold<double>(0, (sum, item) => sum + item.subtotal);

  void _applyItems(List<CartItem> items) {
    if (!mounted) return;
    setState(() => _items = List<CartItem>.of(items));
    widget.onChanged(List<CartItem>.unmodifiable(items));
  }

  Future<void> _changeQuantity(CartItem item, int adjustment) async {
    if (_isSaving) return;
    final index = _items.indexWhere((entry) => entry.product.id == item.product.id);
    if (index < 0) return;
    final quantity = _items[index].quantity + adjustment;
    setState(() => _isSaving = true);
    try {
      final updatedItems = await widget.repository.updateQuantity(
        item.product.id,
        quantity,
      );
      _applyItems(updatedItems);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _clearCart() async {
    if (_items.isEmpty || _isSaving) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Limpar carrinho?'),
        content: const Text('Todos os produtos serão removidos do carrinho.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Limpar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSaving = true);
    try {
      final emptyCart = await widget.repository.clear();
      _applyItems(emptyCart);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _finishPurchase() async {
    if (_items.isEmpty || _isSaving) return;

    final completedTotal = _total;
    setState(() => _isSaving = true);
    try {
      final emptyCart = await widget.repository.clear();
      _applyItems(emptyCart);
      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.check_circle_outline, color: _primary, size: 48),
          title: const Text('Compra finalizada!'),
          content: Text(
            'Pedido concluído com sucesso. Total: ${formatBrazilianCurrency(completedTotal)}.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Continuar comprando'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Carrinho',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: 'Limpar carrinho',
                  onPressed: _items.isEmpty || _isSaving ? null : _clearCart,
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: 'Fechar carrinho',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _isSaving && _items.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _items.isEmpty
                    ? const Center(child: Text('Seu carrinho está vazio.'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          return Card(
                            child: ListTile(
                              leading: _productImage(item.product.imagem),
                              title: Text(item.product.descricao),
                              subtitle: Text(
                                '${formatBrazilianCurrency(item.product.valor)} cada\n'
                                'Subtotal: ${formatBrazilianCurrency(item.subtotal)}',
                              ),
                              isThreeLine: true,
                              trailing: SizedBox(
                                width: 132,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      tooltip: 'Diminuir ou remover produto',
                                      onPressed: _isSaving
                                          ? null
                                          : () => _changeQuantity(item, -1),
                                      icon: const Icon(Icons.remove_circle_outline),
                                    ),
                                    Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    IconButton(
                                      tooltip: 'Aumentar quantidade',
                                      onPressed: _isSaving
                                          ? null
                                          : () => _changeQuantity(item, 1),
                                      icon: const Icon(Icons.add_circle_outline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
          if (_items.isNotEmpty) ...[
            const Divider(height: 1),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          formatBrazilianCurrency(_total),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _finishPurchase,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Finalizar compra'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );

  Widget _productImage(String url) => ClipRRect(
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
}
