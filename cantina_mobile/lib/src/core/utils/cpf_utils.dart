import 'package:flutter/services.dart';

const _tamanhoCpf = 11;

/// Converte o CPF (com ou sem máscara) no identificador interno do Supabase Auth.
/// Lança [FormatException] se não houver exatamente 11 dígitos.
String cpfToAuthEmail(String cpf) {
  final digits = cpf.replaceAll(RegExp(r'\D'), '');
  if (digits.length != _tamanhoCpf) {
    throw const FormatException('CPF deve conter exatamente 11 dígitos.');
  }
  return '$digits@cpf.cantinafacil.app';
}

/// Aceita CPF (vira e-mail interno) ou e-mail real (usado direto).
String loginToAuthEmail(String entrada) {
  final texto = entrada.trim();
  if (texto.contains('@')) return texto.toLowerCase();
  return cpfToAuthEmail(texto);
}

/// Máscara 000.000.000-00 enquanto o usuário digita.
class CpfInputFormatter extends TextInputFormatter {
  const CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitado = digits.length > _tamanhoCpf
        ? digits.substring(0, _tamanhoCpf)
        : digits;
    final buffer = StringBuffer();
    for (var i = 0; i < limitado.length; i++) {
      if (i == 3 || i == 6) buffer.write('.');
      if (i == 9) buffer.write('-');
      buffer.write(limitado[i]);
    }
    final texto = buffer.toString();
    return TextEditingValue(
      text: texto,
      selection: TextSelection.collapsed(offset: texto.length),
    );
  }
}

/// Mascara o CPF só enquanto o texto não parece e-mail (sem letras nem @).
class LoginInputFormatter extends TextInputFormatter {
  const LoginInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (RegExp(r'[A-Za-z@]').hasMatch(newValue.text)) return newValue;
    return const CpfInputFormatter().formatEditUpdate(oldValue, newValue);
  }
}
