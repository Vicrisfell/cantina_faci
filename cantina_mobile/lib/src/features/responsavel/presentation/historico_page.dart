import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/responsavel_repository.dart';
import '../domain/responsavel_models.dart';
import 'responsavel_ui_state.dart';
import 'widgets/responsavel_widgets.dart';

class HistoricoPage extends ConsumerWidget {
  const HistoricoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return carregamentoOuErro(
      ref.watch(responsavelDataProvider),
      ref,
      (dados) => _HistoricoConteudo(dados: dados),
    );
  }
}

class _HistoricoConteudo extends ConsumerWidget {
  const _HistoricoConteudo({required this.dados});

  final ResponsavelData dados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(historicoFiltroProvider);
    final notifier = ref.read(historicoFiltroProvider.notifier);
    final nomes = {for (final f in dados.filhos) f.id: f.nome};
    final lista = dados.movimentos
        .where((m) => filtro == null || m.alunoId == filtro)
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      children: [
        const CantinaHeader(),
        const SizedBox(height: 12),
        const ResponsavelCabecalhoTitulo(
          titulo: 'Histórico de compras',
          subtitulo: 'Movimentações da carteira de cada aluno.',
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: filtro == null,
                selectedColor: CantinaColors.vinho,
                labelStyle: TextStyle(
                  color: filtro == null ? Colors.white : CantinaColors.vinho,
                  fontWeight: FontWeight.w600,
                ),
                onSelected: (_) => notifier.selecionar(null),
              ),
              for (final f in dados.filhos) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(f.nome.split(' ').first),
                  selected: filtro == f.id,
                  selectedColor: CantinaColors.vinho,
                  labelStyle: TextStyle(
                    color: filtro == f.id ? Colors.white : CantinaColors.vinho,
                    fontWeight: FontWeight.w600,
                  ),
                  onSelected: (_) => notifier.selecionar(f.id),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (lista.isEmpty)
          const CardBranco(child: Text('Nenhuma movimentação encontrada.'))
        else
          for (final m in lista)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LinhaMovimento(
                movimento: m,
                nomeAluno: nomes[m.alunoId] ?? 'Aluno',
              ),
            ),
      ],
    );
  }
}

class _LinhaMovimento extends StatelessWidget {
  const _LinhaMovimento({required this.movimento, required this.nomeAluno});

  final Movimento movimento;
  final String nomeAluno;

  @override
  Widget build(BuildContext context) {
    final m = movimento;
    final data = formatDataHora(m.criadoEm);

    if (!m.isCompra) {
      final entrada = m.tipo == 'credito' || m.tipo == 'transferencia_entrada';
      final titulo = switch (m.tipo) {
        'credito' => 'Recarga de saldo',
        'transferencia_entrada' => 'Transferência recebida',
        _ => 'Transferência enviada',
      };
      final cor = entrada ? CantinaColors.verdeTexto : CantinaColors.vinho;
      return CardBranco(
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: entrada ? CantinaColors.verdeFundo : CantinaColors.bege,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                entrada ? Icons.arrow_downward : Icons.arrow_upward,
                color: cor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '$nomeAluno · $data',
                    style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
                  ),
                ],
              ),
            ),
            Text(
              '${entrada ? '+' : '-'} ${formatReais(m.valor.abs())}',
              style: TextStyle(fontWeight: FontWeight.w800, color: cor),
            ),
          ],
        ),
      );
    }

    final itens = m.venda?.itens ?? const <ItemVenda>[];
    return CardBranco(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(vertical: 6),
          childrenPadding: const EdgeInsets.only(bottom: 12),
          shape: const Border(),
          collapsedShape: const Border(),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: CantinaColors.bege,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lunch_dining, color: CantinaColors.vinho),
          ),
          title: Text(
            itens.isEmpty ? 'Compra' : itens.first.produto,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            '$nomeAluno · $data',
            style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
          ),
          trailing: Text(
            formatReais(m.valor.abs()),
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: CantinaColors.vinho,
            ),
          ),
          children: [
            if (itens.isEmpty)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sem detalhes dos itens.',
                  style: TextStyle(color: CantinaColors.cinza),
                ),
              ),
            for (final i in itens)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${formatQuantidadeCurta(i.quantidade)}x ${i.produto}',
                      ),
                    ),
                    Text(formatReais(i.total)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
