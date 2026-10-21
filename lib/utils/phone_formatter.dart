import 'package:flutter/services.dart';

/// Formata números brasileiros conforme a quantidade de dígitos informada.
///
/// Dez dígitos representam um telefone fixo: (00) 0000-0000.
/// Onze dígitos representam um celular: (00) 00000-0000.
String formatBrazilianPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  final phone = digits.length > 11 ? digits.substring(0, 11) : digits;

  if (phone.length <= 2) return phone.isEmpty ? '' : '($phone';

  final areaCode = phone.substring(0, 2);
  final number = phone.substring(2);
  final firstPartLength = phone.length == 11 ? 5 : 4;

  if (number.length <= firstPartLength) return '($areaCode) $number';

  return '($areaCode) ${number.substring(0, firstPartLength)}-${number.substring(firstPartLength)}';
}

/// Aplica a máscara enquanto o usuário digita e aceita no máximo 11 dígitos.
class BrazilianPhoneInputFormatter extends TextInputFormatter {
  const BrazilianPhoneInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = formatBrazilianPhone(newValue.text);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
