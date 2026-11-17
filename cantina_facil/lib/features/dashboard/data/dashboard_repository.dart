import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/dashboard_models.dart';

typedef Linha = Map<String, dynamic>;

/// Coluna de data/hora usada nos filtros de período. Confirme no schema.
const _colData = 'criado_em';
const limiteEstoqueCritico = 10;
const _tamanhoLote = 150; // tamanho máximo de cada `in.(...)`
const _limiteRecentes = 15;

class DashboardRepository {
  SupabaseClient get _db => Supabase.instance.client;

  // ------------------------------------------------------------ Diagnóstico

  Future<T> _executar<T>(String rotulo, Future<T> Function() operacao) async {
    try {
      return await operacao();
    } on PostgrestException catch (e, st) {
      debugPrint('[DashboardRepository] PostgrestException em "$rotulo"\n'
          '  code:    ${e.code}\n'
          '  message: ${e.message}\n'
          '  details: ${e.details}\n'
          '  hint:    ${e.hint}\n'
          '$st');
      rethrow;
    } catch (e, st) {
      debugPrint('[DashboardRepository] Erro inesperado em "$rotulo": $e\n$st');
      rethrow;
    }
  }

  // ------------------------------------------------------------ Cadastros

  Future<String> nomeOrganizacao(String idOrg) =>
      _executar('organizacao.nome', () async {
        final r = await _db
            .from('organizacao')
            .select('nome_organizacao')
            .eq('id_organizacao', idOrg)
            .single();
        return r['nome_organizacao'] as String;
      });

  Future<List<UnidadeOpcao>> listarUnidades({
    String? idOrg,
    List<String> idsPermitidos = const [],
  }) =>
      _executar('unidade (lista)', () async {
        final List<Linha> rows;
        if (idOrg != null) {
          rows = await _db
              .from('unidade')
              .select('id_unidade, nome')
              .eq('id_org', idOrg)
              .order('nome');
        } else if (idsPermitidos.isNotEmpty) {
          rows = await _db
              .from('unidade')
              .select('id_unidade, nome')
              .inFilter('id_unidade', idsPermitidos)
              .order('nome');
        } else {
          return <UnidadeOpcao>[];
        }
        return rows
            .map((r) => UnidadeOpcao(
                  id: r['id_unidade'] as String,
                  nome: r['nome'] as String,
                ))
            .toList();
      });

  // ------------------------------------------------------------ Dashboard

  Future<DashboardData> carregar({
    required List<String> idsUnidades,
    DateTime? inicio,
  }) async {
    if (idsUnidades.isEmpty) return DashboardData.vazio();
    final desde = inicio?.toUtc().toIso8601String();

    // Etapa 1: tabelas que dependem apenas das unidades selecionadas.
    final e1 = await Future.wait<List<Linha>>([
      _vendas(idsUnidades, desde),        // 0
      _carteiras(idsUnidades),            // 1
      _alunosAtivos(idsUnidades),         // 2
      _estoqueCritico(idsUnidades),       // 3
      _movimentacoes(idsUnidades, desde), // 4
      _produtos(idsUnidades),             // 5
      _unidades(idsUnidades),             // 6
    ]);
    final vendas = e1[0];
    final carteiras = e1[1];
    final alunosAtivos = e1[2];
    final estoque = e1[3];
    final movs = e1[4];
    final produtos = e1[5];
    final unidades = e1[6];

    // IDs derivados da etapa 1 para a etapa 2.
    final idsVendas = _ids(vendas, 'id_venda');
    final idsPagas = vendas
        .where((v) => v['status'] == 'paid')
        .map((v) => v['id_venda'] as String)
        .toList();
    final idsAlunos = {
      ...vendas.map((v) => v['id_aluno'] as String?).whereType<String>(),
      ...carteiras.map((c) => c['id_aluno'] as String?).whereType<String>(),
    }.toList();

    // Etapa 2: pagamentos, itens e nomes de alunos.
    final e2 = await Future.wait<List<Linha>>([
      _pagamentos(idsVendas),   // 0
      _itensVendidos(idsPagas), // 1
      _alunos(idsAlunos),       // 2
    ]);
    final pagamentos = e2[0];
    final itens = e2[1];
    final alunos = e2[2];

    // Índices para cruzamento em memória.
    final nomeAluno = {
      for (final a in alunos) a['id_aluno'] as String: a['nome_completo_aluno'] as String,
    };
    final nomeProduto = {
      for (final p in produtos) p['id'] as String: p['nome'] as String,
    };
    final nomeUnidade = {
      for (final u in unidades) u['id_unidade'] as String: u['nome'] as String,
    };
    final alunoDaCarteira = {
      for (final c in carteiras) c['id_carteira'] as String: c['id_aluno'] as String?,
    };

    final pagPorVenda = <String, List<PagamentoVenda>>{};
    for (final p in pagamentos) {
      pagPorVenda
          .putIfAbsent(p['id_venda'] as String, () => [])
          .add(PagamentoVenda(p['metodo'] as String, _num(p['valor'])));
    }

    final vendasModelo = vendas.map((v) {
      final idAluno = v['id_aluno'] as String?;
      return VendaResumo(
        id: v['id_venda'] as String,
        criadoEm: _data(v[_colData]),
        status: v['status'] as String,
        total: _num(v['total']),
        unidadeNome: nomeUnidade[v['id_unid']] ?? '—',
        alunoNome: idAluno == null ? null : nomeAluno[idAluno],
        pagamentos: pagPorVenda[v['id_venda']] ?? const [],
      );
    }).toList();

    final estoqueModelo = estoque.map((e) {
      return EstoqueItem(
        idUnidade: e['id_unidade'] as String,
        idProduto: e['id_produto'] as String,
        produtoNome: nomeProduto[e['id_produto']] ?? 'Produto',
        unidadeNome: nomeUnidade[e['id_unidade']] ?? '—',
        quantidade: (e['quantidade'] as num).toInt(),
      );
    }).toList()
      ..sort((a, b) => a.quantidade.compareTo(b.quantidade));

    MovimentacaoResumo movModelo(Linha m) {
      final idAluno = alunoDaCarteira[m['id_carteira']];
      return MovimentacaoResumo(
        tipo: m['tipo'] as String,
        valor: _num(m['valor']),
        criadoEm: _data(m[_colData]),
        alunoNome: idAluno == null ? null : nomeAluno[idAluno],
      );
    }

    final movModelos = movs.map(movModelo).toList()
      ..sort((a, b) => b.criadoEm.compareTo(a.criadoEm));

    final itensModelo = itens.map((i) {
      return ItemVenda(
        nome: nomeProduto[i['id_produto']] ?? 'Produto',
        quantidade: (i['quantidade'] as num).toInt(),
        precoUnitario: _num(i['preco_unitario']),
      );
    }).toList();

    return DashboardData.montar(
      vendas: vendasModelo,
      saldoCarteiras: carteiras.fold<double>(0, (s, c) => s + _num(c['saldo'])),
      alunosAtivos: alunosAtivos.map((a) => a['id_aluno']).toSet().length,
      estoqueBaixo: estoqueModelo,
      movimentacoesPeriodo: movModelos,
      ultimasMovimentacoes: movModelos.take(_limiteRecentes).toList(),
      itensVendidos: itensModelo,
    );
  }

  // ------------------------------------------------------------ Etapa 1

  Future<List<Linha>> _vendas(List<String> ids, String? desde) =>
      _executar('venda', () async {
        var q = _db
            .from('venda')
            .select('id_venda, id_unid, id_aluno, status, total, $_colData')
            .inFilter('id_unid', ids);
        if (desde != null) q = q.gte(_colData, desde);
        return await q.order(_colData, ascending: false);
      });

  Future<List<Linha>> _carteiras(List<String> ids) =>
      _executar('carteira', () async {
        return await _db
            .from('carteira')
            .select('id_carteira, id_aluno, id_unid, saldo')
            .inFilter('id_unid', ids);
      });

  Future<List<Linha>> _alunosAtivos(List<String> ids) =>
      _executar('aluno_unidade (ativos)', () async {
        return await _db
            .from('aluno_unidade')
            .select('id_aluno')
            .inFilter('id_unid', ids)
            .eq('ativo', true);
      });

  Future<List<Linha>> _estoqueCritico(List<String> ids) =>
      _executar('estoque (crítico)', () async {
        return await _db
            .from('estoque')
            .select('id_unidade, id_produto, quantidade')
            .inFilter('id_unidade', ids)
            .lte('quantidade', limiteEstoqueCritico)
            .order('quantidade');
      });

  Future<List<Linha>> _movimentacoes(List<String> ids, String? desde) =>
      _executar('movimentacao_carteira', () async {
        var q = _db
            .from('movimentacao_carteira')
            .select('id_carteira, id_unid, tipo, valor, $_colData')
            .inFilter('id_unid', ids);
        if (desde != null) q = q.gte(_colData, desde);
        return await q.order(_colData, ascending: false);
      });

  Future<List<Linha>> _produtos(List<String> ids) =>
      _executar('produto', () async {
        return await _db
            .from('produto')
            .select('id, id_unidade, nome')
            .inFilter('id_unidade', ids);
      });

  Future<List<Linha>> _unidades(List<String> ids) =>
      _executar('unidade (nomes)', () async {
        return await _db
            .from('unidade')
            .select('id_unidade, nome')
            .inFilter('id_unidade', ids);
      });

  // ------------------------------------------------------------ Etapa 2 (por lote)

  Future<List<Linha>> _pagamentos(List<String> idsVendas) =>
      _porLotes('pagamento_venda', idsVendas, (lote) async {
        return await _db
            .from('pagamento_venda')
            .select('id_venda, metodo, valor')
            .inFilter('id_venda', lote);
      });

  Future<List<Linha>> _itensVendidos(List<String> idsVendasPagas) =>
      _porLotes('itens_venda (vendas pagas)', idsVendasPagas, (lote) async {
        return await _db
            .from('itens_venda')
            .select('id_venda, id_produto, quantidade, preco_unitario')
            .inFilter('id_venda', lote);
      });

  Future<List<Linha>> _alunos(List<String> idsAlunos) =>
      _porLotes('aluno (nomes)', idsAlunos, (lote) async {
        return await _db
            .from('aluno')
            .select('id_aluno, nome_completo_aluno')
            .inFilter('id_aluno', lote);
      });

  /// Divide `ids` em lotes, executa em paralelo e concatena os resultados.
  Future<List<Linha>> _porLotes(
    String rotulo,
    List<String> ids,
    Future<List<Linha>> Function(List<String> lote) buscar,
  ) {
    if (ids.isEmpty) return Future.value(<Linha>[]);
    return _executar(rotulo, () async {
      final partes = await Future.wait<List<Linha>>([
        for (var i = 0; i < ids.length; i += _tamanhoLote)
          buscar(ids.sublist(i, min(i + _tamanhoLote, ids.length))),
      ]);
      return partes.expand((p) => p).toList();
    });
  }

  // ------------------------------------------------------------ Detalhes e ações

  Future<List<ItemVenda>> itensDaVenda(String idVenda) =>
      _executar('itens_venda (detalhe)', () async {
        final itens = await _db
            .from('itens_venda')
            .select('id_produto, quantidade, preco_unitario')
            .eq('id_venda', idVenda);
        if (itens.isEmpty) return <ItemVenda>[];

        final produtos = await _db
            .from('produto')
            .select('id, nome')
            .inFilter('id', _ids(itens, 'id_produto'));
        final nomes = {for (final p in produtos) p['id'] as String: p['nome'] as String};

        return itens
            .map((i) => ItemVenda(
                  nome: nomes[i['id_produto']] ?? 'Produto',
                  quantidade: (i['quantidade'] as num).toInt(),
                  precoUnitario: _num(i['preco_unitario']),
                ))
            .toList();
      });

  Future<void> estornarVenda(String idVenda) =>
      _executar('rpc estornar_venda', () async {
        await _db.rpc('estornar_venda', params: {'p_id_venda': idVenda});
      });

  Future<void> definirEstoque({
    required String idUnidade,
    required String idProduto,
    required int quantidade,
  }) =>
      _executar('estoque (update)', () async {
        await _db
            .from('estoque')
            .update({'quantidade': quantidade})
            .eq('id_unidade', idUnidade)
            .eq('id_produto', idProduto);
      });

  // ------------------------------------------------------------ Tempo real

  RealtimeChannel assinarMudancas(void Function() aoMudar) {
    final canal = _db.channel('dashboard-cantina');
    for (final tabela in const ['venda', 'itens_venda', 'movimentacao_carteira', 'estoque']) {
      canal.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: tabela,
        callback: (_) => aoMudar(),
      );
    }
    return canal.subscribe();
  }

  Future<void> cancelarAssinatura(RealtimeChannel canal) => _db.removeChannel(canal);

  // ------------------------------------------------------------ Helpers

  List<String> _ids(List<Linha> rows, String coluna) =>
      rows.map((r) => r[coluna] as String).toSet().toList();

  double _num(Object? v) => v is num ? v.toDouble() : double.tryParse('$v') ?? 0;

  DateTime _data(Object? v) => DateTime.parse('$v').toLocal();
}
