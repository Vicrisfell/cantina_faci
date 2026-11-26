import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme/cantina_colors.dart';
import '../../../../core/utils/formatters.dart';

class CardOp extends StatelessWidget {
  const CardOp({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borda,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? borda;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: CantinaColors.branco,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borda ?? const Color(0xFFE8DCC8),
          width: borda == null ? 1 : 1.5,
        ),
      ),
      child: child,
    );
  }
}

class TituloEtapa extends StatelessWidget {
  const TituloEtapa({
    super.key,
    this.etapa,
    required this.titulo,
    required this.subtitulo,
  });

  final String? etapa;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (etapa != null)
          Text(
            etapa!,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: CantinaColors.vinho,
            ),
          ),
        if (etapa != null) const SizedBox(height: 6),
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: CantinaColors.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitulo,
          style: const TextStyle(fontSize: 13, color: CantinaColors.cinza),
        ),
      ],
    );
  }
}

class BotaoPrimario extends StatelessWidget {
  const BotaoPrimario({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: CantinaColors.vinho,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFCFC3B0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class BotaoContorno extends StatelessWidget {
  const BotaoContorno({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: CantinaColors.vinho,
          side: const BorderSide(color: CantinaColors.vinho),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    );
  }
}

class CampoBusca extends StatelessWidget {
  const CampoBusca({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final borda = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE8DCC8)),
    );
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: CantinaColors.cinza),
        isDense: true,
        filled: true,
        fillColor: CantinaColors.branco,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: borda,
        enabledBorder: borda,
        focusedBorder: borda.copyWith(
          borderSide: const BorderSide(color: CantinaColors.vinho),
        ),
      ),
    );
  }
}

class SeletorQuantidade extends StatelessWidget {
  const SeletorQuantidade({
    super.key,
    required this.valor,
    required this.onMenos,
    this.onMais,
  });

  final int valor;
  final VoidCallback onMenos;
  final VoidCallback? onMais;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Quantidade',
          style: TextStyle(fontSize: 11, color: CantinaColors.cinza),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton.outlined(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.remove, size: 18),
              onPressed: onMenos,
            ),
            SizedBox(
              width: 32,
              child: Text(
                '$valor',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            IconButton.outlined(
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.add, size: 18),
              onPressed: onMais,
            ),
          ],
        ),
      ],
    );
  }
}

class ErroOperador extends StatelessWidget {
  const ErroOperador({super.key, required this.onTentar});

  final VoidCallback onTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Não foi possível carregar os dados.'),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onTentar, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

Widget linhaResumo(
  String rotulo,
  String valor, {
  bool destaque = false,
  Color? cor,
}) {
  final estilo = TextStyle(
    fontSize: destaque ? 16 : 14,
    fontWeight: destaque ? FontWeight.w800 : FontWeight.w500,
    color: cor ?? CantinaColors.ink,
  );
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Expanded(child: Text(rotulo, style: estilo)),
        Text(valor, style: estilo),
      ],
    ),
  );
}

String mensagemErroOperador(Object erro) {
  if (erro is PostgrestException) {
    final texto = erro.message.toLowerCase();
    if (texto.contains('saldo')) return 'Saldo insuficiente para esta compra.';
    if (texto.contains('estoque')) {
      return 'Estoque insuficiente para um dos produtos.';
    }
    if (texto.contains('estorn')) return 'Não foi possível estornar esta venda.';
    if (erro.code == '42501') return 'Você não tem permissão para esta ação.';
    return 'Não foi possível concluir a operação. Tente novamente.';
  }
  return 'Sem conexão ou erro inesperado. Tente novamente.';
}

void mostrarSnack(BuildContext context, String mensagem) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(mensagem)));
}

String formatarSaldoOperador(double valor) => formatReais(valor);
