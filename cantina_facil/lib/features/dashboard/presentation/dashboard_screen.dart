import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../core/format.dart';
import '../../../core/sessao.dart';
import '../../../core/theme/app_theme.dart';
import '../controller/dashboard_controller.dart';
import '../data/dashboard_repository.dart';
import '../models/dashboard_models.dart';
import 'dashboard_widgets.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final acesso = Sessao.perfil;
    if (acesso == null) {
      return const Center(child: Text('Sessão expirada. Faça login novamente.'));
    }
    return ChangeNotifierProvider(
      create: (_) => DashboardController(
        repo: DashboardRepository(),
        idOrg: acesso.orgId,
        idsGerenciados: acesso.managedUnitIds,
      )..iniciar(),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DashboardController>();

    if (c.carregandoInicial) {
      return const Center(child: CircularProgressIndicator());
    }
    final d = c.dados;
    if (d == null) {
      return ErroPainel(erro: c.erro, onTentar: c.recarregar);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: c.atualizando ? 0.55 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Cabecalho(c: c),
            const SizedBox(height: 16),
            if (c.erro != null) BannerErro(onTentar: c.recarregar),
            KpiGrid(d: d),
            const SizedBox(height: 16),
            Duas(
              esquerda: Caixa(
                titulo: 'Evolução de Vendas',
                child: GraficoFaturamento(pontos: d.faturamentoPorDia),
              ),
              direita: Caixa(
                titulo: 'Métodos de Pagamento',
                child: GraficoMetodos(metodos: d.metodosPagamento),
              ),
            ),
            const SizedBox(height: 16),
            Duas(
              esquerda: Caixa(
                titulo: 'Últimas Vendas',
                child: TabelaVendas(vendas: d.ultimasVendas, c: c),
              ),
              direita: Column(
                children: [
                  Caixa(
                    titulo: 'Alertas de Estoque Baixo',
                    child: ListaEstoque(itens: d.estoqueBaixo, c: c),
                  ),
                  const SizedBox(height: 16),
                  Caixa(
                    titulo: 'Produtos Mais Vendidos',
                    child: ListaTopProdutos(produtos: d.topProdutos),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Caixa(
              titulo: 'Últimas Movimentações de Carteira',
              child: TabelaMovimentacoes(movs: d.ultimasMovimentacoes),
            ),
          ],
        ),
      ),
    );
  }
}

class Cabecalho extends StatelessWidget {
  const Cabecalho({super.key, required this.c});
  final DashboardController c;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Visão Geral da Cantina',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.bordo),
            ),
            Text(c.nomeOrganizacao, style: const TextStyle(fontSize: 14, color: AppColors.marrom)),
          ],
        ),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: caixaDecoracao(),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String?>(
                  value: c.unidadeSelecionada,
                  hint: const Text('Unidade'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas as Unidades da Organização'),
                    ),
                    for (final u in c.unidades)
                      DropdownMenuItem<String?>(value: u.id, child: Text(u.nome)),
                  ],
                  onChanged: c.selecionarUnidade,
                ),
              ),
            ),
            SegmentedButton<PeriodoDashboard>(
              segments: [
                for (final p in PeriodoDashboard.values)
                  ButtonSegment(value: p, label: Text(p.rotulo)),
              ],
              selected: {c.periodo},
              onSelectionChanged: (s) => c.selecionarPeriodo(s.first),
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.bordo,
                selectedForegroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.d});
  final DashboardData d;

  @override
  Widget build(BuildContext context) {
    final cards = [
      KpiCard(
        icone: Icons.point_of_sale,
        titulo: 'Faturamento no Período',
        valor: moeda.format(d.faturamento),
        subtitulo: '${d.qtdVendasPagas} vendas pagas',
      ),
      KpiCard(
        icone: Icons.receipt_long,
        titulo: 'Ticket Médio & Recargas',
        valor: moeda.format(d.ticketMedio),
        subtitulo: 'Recargas: ${moeda.format(d.totalRecargas)} (${d.qtdRecargas})',
      ),
      KpiCard(
        icone: Icons.account_balance_wallet,
        titulo: 'Saldo Total em Carteiras',
        valor: moeda.format(d.saldoCarteiras),
        subtitulo: 'Soma das carteiras dos alunos',
      ),
      KpiCard(
        icone: Icons.school,
        titulo: 'Alunos Ativos',
        valor: '${d.alunosAtivos}',
        subtitulo: '${d.estoqueCritico} produto(s) com estoque crítico',
        alerta: d.estoqueCritico > 0,
      ),
    ];

    return LayoutBuilder(builder: (context, cons) {
      final colunas = cons.maxWidth >= 1100 ? 4 : (cons.maxWidth >= 640 ? 2 : 1);
      const gap = 16.0;
      final largura = (cons.maxWidth - gap * (colunas - 1)) / colunas;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final k in cards) SizedBox(width: largura, child: k)],
      );
    });
  }
}

class ErroPainel extends StatelessWidget {
  const ErroPainel({super.key, required this.erro, required this.onTentar});
  final Object? erro;
  final Future<void> Function() onTentar;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 56, color: AppColors.vermelhoToldo),
          const SizedBox(height: 12),
          const Text('Erro ao carregar o painel',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.bordo)),
          const SizedBox(height: 4),
          Text('$erro', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(onPressed: onTentar, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }
}
