String formatBrazilianCurrency(num value) {
  final parts = value.toStringAsFixed(2).split('.');
  final integer = parts[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return 'R\$ $integer,${parts[1]}';
}
