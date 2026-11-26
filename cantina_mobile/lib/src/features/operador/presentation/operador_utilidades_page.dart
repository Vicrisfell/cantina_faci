import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/operador_repository.dart';
import '../domain/operador_models.dart';
import 'widgets/operador_widgets.dart';

class _ScaffoldOp extends StatelessWidget {
  const _ScaffoldOp({required this.titulo, required this.child});

  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CantinaColors.creme,
      appBar: AppBar(
        backgroundColor: CantinaColors.creme,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: CantinaColors.vinho,
        title: Text(
          titulo,
          style: const TextStyle(
            color: CantinaColors.vinho,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: child,
    );
  }
}

class RecargaPage extends ConsumerWidget {
  const RecargaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(catalogoProvider);
    return _ScaffoldOp(
      titulo: 'Recarga de carteira',
      child: catalogo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErroOperador(
          onTentar: () => ref.invalidate(catalogoProvider),
        ),
        data: (cat) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Escolha o aluno e informe o valor recebido no balcão.',
              style: TextStyle(color: CantinaColors.cinza),
            ),
            const SizedBox(height: 16),
            if (cat.alunos.isEmpty)
              const Text('Nenhum aluno ativo nesta unidade.'),
            for (final a in cat.alunos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CardOp(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.nome,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(
                              'Saldo: ${formatReais(a.saldo)}',
                              style: const TextStyle(
                                  fontSize: 12, color: CantinaColors.cinza),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CantinaColors.vinho,
                          side: const BorderSide(color: CantinaColors.vinho),
                        ),
                        onPressed: () => _recarregar(context, ref, a),
                        child: const Text('Recarregar'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _recarregar(
    BuildContext context,
    WidgetRef ref,
    AlunoVenda aluno,
  ) async {
    final carteiraId = aluno.carteiraId;
    if (carteiraId == null) {
      mostrarSnack(context, 'Este aluno não tem carteira nesta unidade.');
      return;
    }
    final controller = TextEditingController(text: '20');
    final valor = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Recarregar ${aluno.nome}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Valor (R\$)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CantinaColors.vinho),
            onPressed: () => Navigator.pop<double>(
              ctx,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (valor == null || valor <= 0) {
      if (context.mounted && valor != null) {
        mostrarSnack(context, 'Informe um valor maior que zero.');
      }
      return;
    }
    try {
      final novoSaldo = await ref
          .read(operadorRepositoryProvider)
          .recarregarCarteira(carteiraId: carteiraId, valor: valor);
      ref.invalidate(catalogoProvider);
      if (context.mounted) {
        mostrarSnack(context, 'Recarga concluída. Novo saldo: ${formatReais(novoSaldo)}');
      }
    } on PostgrestException catch (erro) {
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    } catch (erro) {
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    }
  }
}

class EstoquePage extends ConsumerWidget {
  const EstoquePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalogo = ref.watch(catalogoProvider);
    return _ScaffoldOp(
      titulo: 'Estoque',
      child: catalogo.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErroOperador(
          onTentar: () => ref.invalidate(catalogoProvider),
        ),
        data: (cat) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Consulte e ajuste a quantidade disponível de cada produto.',
              style: TextStyle(color: CantinaColors.cinza),
            ),
            const SizedBox(height: 16),
            if (cat.produtos.isEmpty)
              const Text('Nenhum produto ativo nesta unidade.'),
            for (final p in cat.produtos)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CardOp(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.nome,
                                style: const TextStyle(fontWeight: FontWeight.w800)),
                            Text(
                              '${formatReais(p.preco)} • Estoque: '
                              '${formatQuantidadeCurta(p.estoque)}',
                              style: const TextStyle(
                                  fontSize: 12, color: CantinaColors.cinza),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CantinaColors.vinho,
                          side: const BorderSide(color: CantinaColors.vinho),
                        ),
                        onPressed: () => _ajustar(context, ref, p),
                        child: const Text('Ajustar'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _ajustar(
    BuildContext context,
    WidgetRef ref,
    ProdutoVenda produto,
  ) async {
    final unidadeId = ref.read(unidadeAtivaIdProvider);
    if (unidadeId == null) return;
    final controller = TextEditingController(
      text: formatQuantidadeCurta(produto.estoque),
    );
    final nova = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(produto.nome),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Nova quantidade em estoque'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CantinaColors.vinho),
            onPressed: () => Navigator.pop<double>(
              ctx,
              double.tryParse(controller.text.replaceAll(',', '.')),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (nova == null) return;
    if (nova < 0) {
      if (context.mounted) mostrarSnack(context, 'A quantidade não pode ser negativa.');
      return;
    }
    try {
      await ref.read(operadorRepositoryProvider).ajustarEstoque(
            unidadeId: unidadeId,
            produtoId: produto.id,
            quantidade: nova,
          );
      ref.invalidate(catalogoProvider);
      if (context.mounted) mostrarSnack(context, 'Estoque atualizado.');
    } on PostgrestException catch (erro) {
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    } catch (erro) {
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    }
  }
}
