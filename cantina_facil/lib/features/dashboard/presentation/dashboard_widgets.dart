import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../core/format.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_models.dart';

const _verde = Color(0xFF2E7D32);

BoxDecoration caixaDecoracao() => BoxDecoration(
      color: AppColors.branco,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0x1F5E1914)),
      boxShadow: const [BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2))],
    );

// ----------------------------------------------------------------- Layout

class Duas extends StatelessWidget {
  const Duas({super.key, required this.esquerda, required this.direita});
  final Widget esquerda;
  final Widget direita;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, cons) {
      if (cons.maxWidth >= 1100) {
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 3, child: esquerda),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: direita),
            ],
          ),
        );
      }
      return Column(children: [esquerda, const SizedBox(height: 16), direita]);
    });
  }
}

class Caixa extends StatelessWidget {
  const Caixa({super.key, required this.titulo, required this.child});
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: caixaDecoracao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.bordo)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.icone,
    required this.titulo,
    required this.valor,
    required this.subtitulo,
    this.alerta = false,
  });

  final IconData icone;
  final String titulo;
  final String valor;
  final String subtitulo;
  final bool alerta;

  @override
  Widget build(BuildContext context) {
    final cor = alerta ? AppColors.alerta : AppColors.vermelhoToldo;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: caixaDecoracao(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icone, color: cor),
          const SizedBox(height: 12),
          Text(titulo, style: const TextStyle(fontSize: 13, color: AppColors.marrom)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              valor,
              style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.bordo),
            ),
          ),
          const SizedBox(height: 4),
          Text(subtitulo, style: TextStyle(fontSize: 12, color: cor)),
        ],
      ),
    );
  }
}

class BannerErro extends StatelessWidget {
  const BannerErro({super.key, required this.onTentar});
  final Future<void> Function() onTentar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.vermelhoToldo.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.vermelhoToldo),
          const SizedBox(width: 8),
          const Expanded(child: Text('Não foi possível atualizar os dados. Exibindo a última carga.')),
          TextButton(onPressed: onTentar, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}

class VazioWidget extends StatelessWidget {
  const VazioWidget(this.mensagem, {super.key});
  final String mensagem;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inbox_outlined, size: 40, color: AppColors.marrom.withValues(alpha: 0.4)),
              const SizedBox(height: 8),
              Text(mensagem, style: TextStyle(color: AppColors.marrom.withValues(alpha: 0.7))),
            ],
          ),
        ),
      );
}

// ----------------------------------------------------------------- Gráficos

class GraficoFaturamento extends StatelessWidget {
  const GraficoFaturamento({super.key, required this.pontos});
  final List<ValorDia> pontos;

  @override
  Widget build(BuildContext context) {
    if (pontos.isEmpty) return const VazioWidget('Nenhuma venda paga no período');
    final visiveis = pontos.length > 31 ? pontos.sublist(pontos.length - 31) : pontos;

    return SizedBox(
      height: 260,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          gridData: const FlGridData(drawVerticalLine: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(),
            rightTitles: const AxisTitles(),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= visiveis.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(dataCurta.format(visiveis[i].dia), style: const TextStyle(fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < visiveis.length; i++)
              BarChartGroupData(x: i, barRods: [
                BarChartRodData(
                  toY: visiveis[i].valor,
                  color: AppColors.vermelhoToldo,
                  width: 14,
                  borderRadius: BorderRadius.circular(4),
                ),
              ]),
          ],
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                moeda.format(rod.toY),
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _rotulosMetodo = {
  'wallet': 'Carteira Digital',
  'cash': 'Dinheiro',
  'card': 'Cartão',
  'other': 'Pix/Outros',
};

Color _corMetodo(String m) => switch (m) {
      'wallet' => AppColors.vermelhoToldo,
      'cash' => AppColors.bordo,
      'card' => const Color(0xFFC98B3A),
      _ => const Color(0xFF8A7A6E),
    };

class GraficoMetodos extends StatelessWidget {
  const GraficoMetodos({super.key, required this.metodos});
  final List<ValorMetodo> metodos;

  @override
  Widget build(BuildContext context) {
    if (metodos.isEmpty) return const VazioWidget('Nenhum pagamento no período');
    final total = metodos.fold<double>(0, (s, m) => s + m.valor);

    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PieChart(
            PieChartData(
              centerSpaceRadius: 46,
              sectionsSpace: 2,
              sections: [
                for (final m in metodos)
                  PieChartSectionData(
                    value: m.valor,
                    color: _corMetodo(m.metodo),
                    radius: 34,
                    title: '',
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final m in metodos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: _corMetodo(m.metodo), shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(child: Text(_rotulosMetodo[m.metodo] ?? m.metodo)),
                Text(moeda.format(m.valor), style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 52,
                  child: Text(
                    total == 0 ? '0%' : '${(m.valor / total * 100).toStringAsFixed(1)}%',
                    textAlign: TextAlign.right,
                    style: const TextStyle(color: AppColors.marrom),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ----------------------------------------------------------------- Tabelas

class BadgeStatus extends StatelessWidget {
  const BadgeStatus({super.key, required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (rotulo, cor) = switch (status) {
      'paid' => ('Pago', _verde),
      'pending' => ('Pendente', AppColors.alerta),
      'void' => ('Anulada', const Color(0xFF6B7280)),
      'refunded' => ('Estornada', AppColors.vermelhoToldo),
      _ => (status, AppColors.marrom),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(rotulo, style: TextStyle(color: cor, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

class TabelaVendas extends StatelessWidget {
  const TabelaVendas({super.key, required this.vendas, required this.c});
  final List<VendaResumo> vendas;
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    if (vendas.isEmpty) return const VazioWidget('Nenhuma venda no período');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        columns: const [
          DataColumn(label: Text('Data/Hora')),
          DataColumn(label: Text('Aluno')),
          DataColumn(label: Text('Pagamento')),
          DataColumn(label: Text('Status')),
          DataColumn(label: Text('Valor'), numeric: true),
          DataColumn(label: Text('Ações')),
        ],
        rows: [
          for (final v in vendas)
            DataRow(cells: [
              DataCell(Text(dataHora.format(v.criadoEm))),
              DataCell(Text(v.alunoNome ?? 'Venda Balcão')),
              DataCell(Text(
                v.pagamentos.isEmpty
                    ? '—'
                    : v.pagamentos.map((p) => _rotulosMetodo[p.metodo] ?? p.metodo).join(', '),
              )),
              DataCell(BadgeStatus(status: v.status)),
              DataCell(Text(moeda.format(v.total), style: const TextStyle(fontWeight: FontWeight.w600))),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Ver Itens',
                    icon: const Icon(Icons.list_alt, color: AppColors.bordo),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => ItensVendaDialog(idVenda: v.id, repo: c.repo),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Estornar',
                    icon: const Icon(Icons.undo, color: AppColors.vermelhoToldo),
                    onPressed: v.pago ? () => _confirmarEstorno(context, v) : null,
                  ),
                ],
              )),
            ]),
        ],
      ),
    );
  }

  Future<void> _confirmarEstorno(BuildContext context, VendaResumo v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Estornar venda?'),
        content: Text(
          'O valor de ${moeda.format(v.total)} será devolvido à carteira do aluno '
          'e os itens retornarão ao estoque. Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.vermelhoToldo),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Estornar'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    try {
      await c.estornarVenda(v.id);
      if (context.mounted) _snack(context, 'Venda estornada com sucesso.');
    } catch (e) {
      if (context.mounted) _snack(context, 'Falha ao estornar: $e', error: true);
    }
  }
}

class ItensVendaDialog extends StatelessWidget {
  const ItensVendaDialog({super.key, required this.idVenda, required this.repo});
  final String idVenda;
  final DashboardRepository repo;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Itens da Venda'),
      content: SizedBox(
        width: 420,
        child: FutureBuilder<List<ItemVenda>>(
          future: repo.itensDaVenda(idVenda),
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
            }
            if (snap.hasError) return Text('Erro: ${snap.error}');
            final itens = snap.data ?? const [];
            if (itens.isEmpty) return const VazioWidget('Venda sem itens');
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final i in itens)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(i.nome),
                    subtitle: Text('${i.quantidade} x ${moeda.format(i.precoUnitario)}'),
                    trailing: Text(moeda.format(i.valor), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            );
          },
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))],
    );
  }
}

class ListaEstoque extends StatelessWidget {
  const ListaEstoque({super.key, required this.itens, required this.c});
  final List<EstoqueItem> itens;
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) return const VazioWidget('Nenhum produto com estoque crítico');
    return Column(
      children: [
        for (final i in itens.take(8))
          ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.warning_amber_rounded, color: AppColors.vermelhoToldo),
            title: Text(i.produtoNome),
            subtitle: Text(i.unidadeNome),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.vermelhoToldo.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${i.quantidade} un.',
                      style: const TextStyle(color: AppColors.vermelhoToldo, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () => _repor(context, i),
                  child: const Text('Repor'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Future<void> _repor(BuildContext context, EstoqueItem item) async {
    final campo = TextEditingController(text: '${item.quantidade}');
    final novo = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Repor estoque: ${item.produtoNome}'),
        content: TextField(
          controller: campo,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: 'Nova quantidade (${item.unidadeNome})'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(campo.text)),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    campo.dispose();
    if (novo == null || novo < 0 || !context.mounted) return;

    try {
      await c.definirEstoque(item, novo);
      if (context.mounted) _snack(context, 'Estoque atualizado.');
    } catch (e) {
      if (context.mounted) _snack(context, 'Falha ao atualizar estoque: $e', error: true);
    }
  }
}

class ListaTopProdutos extends StatelessWidget {
  const ListaTopProdutos({super.key, required this.produtos});
  final List<ProdutoRanking> produtos;

  @override
  Widget build(BuildContext context) {
    if (produtos.isEmpty) return const VazioWidget('Sem vendas de produtos no período');
    final max = produtos.first.quantidade.toDouble();
    return Column(
      children: [
        for (var i = 0; i < produtos.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.bordo)),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(produtos[i].nome, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: max == 0 ? 0 : produtos[i].quantidade / max,
                        color: AppColors.vermelhoToldo,
                        backgroundColor: AppColors.vermelhoToldo.withValues(alpha: 0.1),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text('${produtos[i].quantidade} un.', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
      ],
    );
  }
}

class TabelaMovimentacoes extends StatelessWidget {
  const TabelaMovimentacoes({super.key, required this.movs});
  final List<MovimentacaoResumo> movs;

  static const _entradas = {'top_up', 'transfer_in', 'refund'};
  static const _saidas = {'purchase', 'transfer_out'};
  static const _rotulos = {
    'top_up': 'Recarga',
    'purchase': 'Compra',
    'transfer_in': 'Transferência recebida',
    'transfer_out': 'Transferência enviada',
    'refund': 'Estorno',
    'adjustment': 'Ajuste',
  };

  @override
  Widget build(BuildContext context) {
    if (movs.isEmpty) return const VazioWidget('Nenhuma movimentação no período');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Tipo')),
          DataColumn(label: Text('Aluno')),
          DataColumn(label: Text('Valor'), numeric: true),
          DataColumn(label: Text('Data/Hora')),
        ],
        rows: [
          for (final m in movs)
            DataRow(cells: [
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _entradas.contains(m.tipo)
                        ? Icons.arrow_downward
                        : _saidas.contains(m.tipo)
                            ? Icons.arrow_upward
                            : Icons.tune,
                    size: 18,
                    color: _entradas.contains(m.tipo)
                        ? _verde
                        : _saidas.contains(m.tipo)
                            ? AppColors.vermelhoToldo
                            : AppColors.bordo,
                  ),
                  const SizedBox(width: 6),
                  Text(_rotulos[m.tipo] ?? m.tipo),
                ],
              )),
              DataCell(Text(m.alunoNome ?? '—')),
              DataCell(Text(
                '${_saidas.contains(m.tipo) ? '-' : (_entradas.contains(m.tipo) ? '+' : '')}'
                '${moeda.format(m.valor)}',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _entradas.contains(m.tipo)
                      ? _verde
                      : _saidas.contains(m.tipo)
                          ? AppColors.vermelhoToldo
                          : AppColors.marrom,
                ),
              )),
              DataCell(Text(dataHora.format(m.criadoEm))),
            ]),
        ],
      ),
    );
  }
}

void _snack(BuildContext context, String texto, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(texto),
    backgroundColor: error ? AppColors.vermelhoToldo : AppColors.marrom,
  ));
}
