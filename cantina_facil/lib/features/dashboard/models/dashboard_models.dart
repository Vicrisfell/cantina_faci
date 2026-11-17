enum PeriodoDashboard {
  hoje('Hoje'),
  ultimos7('Últimos 7 dias'),
  esteMes('Este Mês'),
  tudo('Tudo');

  const PeriodoDashboard(this.rotulo);
  final String rotulo;

  /// Início do período em hora local. `null` significa sem limite ("Tudo").
  DateTime? inicio(DateTime agora) => switch (this) {
        PeriodoDashboard.hoje => DateTime(agora.year, agora.month, agora.day),
        PeriodoDashboard.ultimos7 =>
          DateTime(agora.year, agora.month, agora.day).subtract(const Duration(days: 6)),
        PeriodoDashboard.esteMes => DateTime(agora.year, agora.month, 1),
        PeriodoDashboard.tudo => null,
      };
}

class UnidadeOpcao {
  const UnidadeOpcao({required this.id, required this.nome});
  final String id; // unidade.id_unidade
  final String nome;
}

class PagamentoVenda {
  const PagamentoVenda(this.metodo, this.valor);
  final String metodo; // wallet | cash | card | other
  final double valor;
}

class VendaResumo {
  const VendaResumo({
    required this.id,
    required this.criadoEm,
    required this.status,
    required this.total,
    required this.unidadeNome,
    required this.pagamentos,
    this.alunoNome,
  });

  final String id;
  final DateTime criadoEm;
  final String status; // paid | pending | void | refunded
  final double total;
  final String unidadeNome;
  final String? alunoNome; // null = venda balcão
  final List<PagamentoVenda> pagamentos;

  bool get pago => status == 'paid';
}

class ItemVenda {
  const ItemVenda({
    required this.nome,
    required this.quantidade,
    required this.precoUnitario,
  });

  final String nome;
  final int quantidade;
  final double precoUnitario;

  double get valor => quantidade * precoUnitario;
}

class EstoqueItem {
  const EstoqueItem({
    required this.idUnidade,
    required this.idProduto,
    required this.produtoNome,
    required this.unidadeNome,
    required this.quantidade,
  });

  final String idUnidade;
  final String idProduto;
  final String produtoNome;
  final String unidadeNome;
  final int quantidade;
}

class MovimentacaoResumo {
  const MovimentacaoResumo({
    required this.tipo,
    required this.valor,
    required this.criadoEm,
    this.alunoNome,
  });

  final String tipo;
  final double valor;
  final DateTime criadoEm;
  final String? alunoNome;
}

class ValorDia {
  const ValorDia(this.dia, this.valor);
  final DateTime dia;
  final double valor;
}

class ValorMetodo {
  const ValorMetodo(this.metodo, this.valor);
  final String metodo;
  final double valor;
}

class ProdutoRanking {
  const ProdutoRanking(this.nome, this.quantidade, this.valor);
  final String nome;
  final int quantidade;
  final double valor;
}

class DashboardData {
  const DashboardData({
    required this.faturamento,
    required this.qtdVendasPagas,
    required this.ticketMedio,
    required this.totalRecargas,
    required this.qtdRecargas,
    required this.saldoCarteiras,
    required this.alunosAtivos,
    required this.estoqueCritico,
    required this.faturamentoPorDia,
    required this.metodosPagamento,
    required this.ultimasVendas,
    required this.estoqueBaixo,
    required this.topProdutos,
    required this.ultimasMovimentacoes,
  });

  final double faturamento;
  final int qtdVendasPagas;
  final double ticketMedio;
  final double totalRecargas;
  final int qtdRecargas;
  final double saldoCarteiras;
  final int alunosAtivos;
  final int estoqueCritico;
  final List<ValorDia> faturamentoPorDia;
  final List<ValorMetodo> metodosPagamento;
  final List<VendaResumo> ultimasVendas;
  final List<EstoqueItem> estoqueBaixo;
  final List<ProdutoRanking> topProdutos;
  final List<MovimentacaoResumo> ultimasMovimentacoes;

  factory DashboardData.vazio() => const DashboardData(
        faturamento: 0,
        qtdVendasPagas: 0,
        ticketMedio: 0,
        totalRecargas: 0,
        qtdRecargas: 0,
        saldoCarteiras: 0,
        alunosAtivos: 0,
        estoqueCritico: 0,
        faturamentoPorDia: [],
        metodosPagamento: [],
        ultimasVendas: [],
        estoqueBaixo: [],
        topProdutos: [],
        ultimasMovimentacoes: [],
      );

  /// Agregação pura em Dart, sem dependência de Supabase.
  factory DashboardData.montar({
    required List<VendaResumo> vendas,
    required double saldoCarteiras,
    required int alunosAtivos,
    required List<EstoqueItem> estoqueBaixo,
    required List<MovimentacaoResumo> movimentacoesPeriodo,
    required List<MovimentacaoResumo> ultimasMovimentacoes,
    required List<ItemVenda> itensVendidos,
  }) {
    final pagas = vendas.where((v) => v.pago).toList();
    final faturamento = pagas.fold<double>(0, (s, v) => s + v.total);
    final recargas = movimentacoesPeriodo.where((m) => m.tipo == 'top_up').toList();

    final porDia = <DateTime, double>{};
    for (final v in pagas) {
      final dia = DateTime(v.criadoEm.year, v.criadoEm.month, v.criadoEm.day);
      porDia.update(dia, (x) => x + v.total, ifAbsent: () => v.total);
    }
    final dias = porDia.entries.map((e) => ValorDia(e.key, e.value)).toList()
      ..sort((a, b) => a.dia.compareTo(b.dia));

    final porMetodo = <String, double>{};
    for (final v in pagas) {
      for (final p in v.pagamentos) {
        porMetodo.update(p.metodo, (x) => x + p.valor, ifAbsent: () => p.valor);
      }
    }
    final metodos = porMetodo.entries.map((e) => ValorMetodo(e.key, e.value)).toList()
      ..sort((a, b) => b.valor.compareTo(a.valor));

    final acumulado = <String, (int, double)>{};
    for (final i in itensVendidos) {
      final atual = acumulado[i.nome] ?? (0, 0.0);
      acumulado[i.nome] = (atual.$1 + i.quantidade, atual.$2 + i.valor);
    }
    final ranking = acumulado.entries
        .map((e) => ProdutoRanking(e.key, e.value.$1, e.value.$2))
        .toList()
      ..sort((a, b) => b.quantidade.compareTo(a.quantidade));

    final recentes = [...vendas]..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    return DashboardData(
      faturamento: faturamento,
      qtdVendasPagas: pagas.length,
      ticketMedio: pagas.isEmpty ? 0 : faturamento / pagas.length,
      totalRecargas: recargas.fold<double>(0, (s, m) => s + m.valor),
      qtdRecargas: recargas.length,
      saldoCarteiras: saldoCarteiras,
      alunosAtivos: alunosAtivos,
      estoqueCritico: estoqueBaixo.length,
      faturamentoPorDia: dias,
      metodosPagamento: metodos,
      ultimasVendas: recentes.take(15).toList(),
      estoqueBaixo: estoqueBaixo,
      topProdutos: ranking.take(5).toList(),
      ultimasMovimentacoes: ultimasMovimentacoes,
    );
  }
}
