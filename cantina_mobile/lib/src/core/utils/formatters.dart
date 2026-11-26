String _dois(int n) => n.toString().padLeft(2, '0');

/// Ex.: 28.5 -> "R$ 28,50"
String formatReais(double valor) {
  final negativo = valor < 0;
  final partes = valor.abs().toStringAsFixed(2).split('.');
  final inteiro = partes[0].replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (_) => '.',
  );
  return '${negativo ? '-' : ''}R\$ $inteiro,${partes[1]}';
}

/// Ex.: 2 -> "2 unidades", 1 -> "1 unidade"
String formatQuantidade(double q) =>
    '${formatQuantidadeCurta(q)} unidade${q == 1 ? '' : 's'}';

/// Ex.: 2 -> "2", 1.5 -> "1,5"
String formatQuantidadeCurta(double q) =>
    q % 1 == 0 ? q.toStringAsFixed(0) : q.toStringAsFixed(1).replaceAll('.', ',');

/// Ex.: 2025-03-28 09:45 -> "28/03/25 às 09:45"
String formatDataHora(DateTime d) =>
    '${_dois(d.day)}/${_dois(d.month)}/${_dois(d.year % 100)} '
    'às ${_dois(d.hour)}:${_dois(d.minute)}';

/// Ex.: 2024-01-10 -> "Desde jan/2024"
String formatDesde(DateTime d) {
  const meses = [
    'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
    'jul', 'ago', 'set', 'out', 'nov', 'dez',
  ];
  return 'Desde ${meses[d.month - 1]}/${d.year}';
}

String formatCpf(String? cpf) {
  final digits = (cpf ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length != 11) return textoOuPadrao(cpf);
  return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
      '${digits.substring(6, 9)}-${digits.substring(9)}';
}

String formatTelefone(String? tel) {
  final digits = (tel ?? '').replaceAll(RegExp(r'\D'), '');
  if (digits.length == 11) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }
  if (digits.length == 10) {
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
  }
  return textoOuPadrao(tel);
}

String textoOuPadrao(String? valor) =>
    (valor == null || valor.trim().isEmpty) ? 'Não informado' : valor.trim();
