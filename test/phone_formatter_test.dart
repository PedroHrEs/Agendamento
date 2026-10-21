import 'package:flutter_test/flutter_test.dart';
import 'package:mobileprimeiro/utils/phone_formatter.dart';

void main() {
  group('formatBrazilianPhone', () {
    test('formata telefone fixo com 10 dígitos', () {
      expect(formatBrazilianPhone('1133334444'), '(11) 3333-4444');
    });

    test('formata celular com 11 dígitos', () {
      expect(formatBrazilianPhone('11988887777'), '(11) 98888-7777');
    });

    test('descarta caracteres que não são dígitos', () {
      expect(formatBrazilianPhone('(11) 98888-7777'), '(11) 98888-7777');
    });
  });
}
