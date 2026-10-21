import 'package:flutter/services.dart';

/// Formata datas no padrão brasileiro `dd/MM/aaaa` enquanto o usuário digita.
class BrazilianDateInputFormatter extends TextInputFormatter {
  const BrazilianDateInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final allDigits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final digits = allDigits.length > 8
        ? allDigits.substring(0, 8)
        : allDigits;

    final formatted = switch (digits.length) {
      <= 2 => digits,
      <= 4 => '${digits.substring(0, 2)}/${digits.substring(2)}',
      _ => '${digits.substring(0, 2)}/${digits.substring(2, 4)}/${digits.substring(4)}',
    };

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
