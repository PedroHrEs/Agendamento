import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/cart_item.dart';
import '../models/shipping_address.dart';
import '../services/shipping_quote_service.dart';
import '../utils/currency_formatter.dart';

class ShippingCheckoutPage extends StatefulWidget {
  const ShippingCheckoutPage({
    required this.items,
    required this.onOrderPlaced,
    super.key,
  });

  final List<CartItem> items;
  final Future<void> Function(double shippingPrice) onOrderPlaced;

  @override
  State<ShippingCheckoutPage> createState() => _ShippingCheckoutPageState();
}

class _ShippingCheckoutPageState extends State<ShippingCheckoutPage> {
  static const _primary = Color(0xFF007A78);
  final _postalCodeController = TextEditingController();
  final _service = ShippingQuoteService();
  ShippingAddress? _address;
  ShippingQuote? _quote;
  String? _postalCodeError;
  bool _isLoading = false;
  bool _isFinishing = false;

  double get _subtotal =>
      widget.items.fold<double>(0, (total, item) => total + item.subtotal);

  Future<void> _calculateShipping() async {
    if (_isLoading || _isFinishing) return;
    final digits = _postalCodeController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 8) {
      setState(() {
        _postalCodeError = 'Informe um CEP válido com 8 números.';
        _address = null;
        _quote = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _postalCodeError = null;
      _address = null;
      _quote = null;
    });
    late final ShippingAddress address;
    try {
      address = await _service.lookupPostalCode(_postalCodeController.text);
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (mounted) {
        setState(() => _postalCodeError = message);
      }
      return;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }

    if (!mounted) return;
    try {
      final quote = _service.quoteFor(address);
      setState(() {
        _address = address;
        _quote = quote;
      });
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _placeOrder() async {
    final quote = _quote;
    if (quote == null || _isFinishing) return;
    setState(() => _isFinishing = true);
    try {
      await widget.onOrderPlaced(quote.price);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      _showError(error);
    } finally {
      if (mounted) setState(() => _isFinishing = false);
    }
  }

  void _showError(Object error) {
    if (!mounted) return;
    final message = error.toString().replaceFirst('Exception: ', '');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Entrega e frete')),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Onde você quer receber?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Informe seu CEP para localizar o endereço e estimar o frete.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _postalCodeController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: InputDecoration(
                  labelText: 'CEP',
                  hintText: '00000-000',
                  errorText: _postalCodeError,
                  errorStyle: const TextStyle(color: Colors.red),
                  prefixIcon: const Icon(Icons.location_on_outlined),
                  suffixIcon: IconButton(
                    tooltip: 'Calcular frete',
                    onPressed: _isLoading ? null : _calculateShipping,
                    icon: const Icon(Icons.search),
                  ),
                ),
                onChanged: (_) {
                  if (_postalCodeError != null) {
                    setState(() => _postalCodeError = null);
                  }
                },
                onSubmitted: (_) => _calculateShipping(),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _isLoading ? null : _calculateShipping,
                style: FilledButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Calcular frete'),
              ),
              if (_address != null && _quote != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle, color: _primary),
                            SizedBox(width: 8),
                            Text(
                              'Endereço localizado',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(_address!.locality),
                        if (_address!.street.isNotEmpty)
                          Text(_address!.street),
                        if (_address!.neighborhood.isNotEmpty)
                          Text(_address!.neighborhood),
                        Text('CEP ${_address!.cep}'),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Frete estimado',
                          value: formatBrazilianCurrency(_quote!.price),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Prazo estimado',
                          value: '${_quote!.estimatedDays} dias úteis',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _SummaryRow(
                          label: 'Produtos',
                          value: formatBrazilianCurrency(_subtotal),
                        ),
                        const SizedBox(height: 8),
                        _SummaryRow(
                          label: 'Frete',
                          value: formatBrazilianCurrency(_quote!.price),
                        ),
                        const Divider(height: 24),
                        _SummaryRow(
                          label: 'Total do pedido',
                          value: formatBrazilianCurrency(_subtotal + _quote!.price),
                          emphasize: true,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Frete e prazo são estimativas calculadas pela região de destino.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: _quote == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: FilledButton.icon(
                    onPressed: _isFinishing ? null : _placeOrder,
                    icon: _isFinishing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: const Text('Confirmar pedido'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ),
      );
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.normal,
              fontSize: emphasize ? 17 : 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: emphasize ? const Color(0xFF007A78) : null,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
              fontSize: emphasize ? 18 : 14,
            ),
          ),
        ],
      );
}
