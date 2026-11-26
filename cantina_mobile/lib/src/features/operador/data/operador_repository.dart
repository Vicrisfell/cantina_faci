import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/supabase_auth_repository.dart';
import '../domain/operador_models.dart';

final operadorRepositoryProvider = Provider<OperadorRepository>(
  (ref) => OperadorRepository(Supabase.instance.client),
);

/// Decide o módulo após o login: operador/gestor (role ou vínculo em membro_unidade)
/// ou responsável.
final perfilAcessoProvider = FutureProvider<PerfilAcesso>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    throw AuthException('Sessão expirada. Entre novamente.');
  }
  final db = Supabase.instance.client;
  final perfil = await db
      .from('cantina_profiles')
      .select('role')
      .eq('id', userId)
      .maybeSingle();
  final role = perfil?['role'] as String?;
  if (role == 'operador' || role == 'gestor') return PerfilAcesso.operador;

  final vinculo = await db
      .from('membro_unidade')
      .select('id_unid')
      .eq('id_usuario', userId)
      .eq('ativo', true)
      .limit(1);
  if (vinculo.isNotEmpty) return PerfilAcesso.operador;
  return PerfilAcesso.responsavel;
});

final unidadesProvider = FutureProvider<List<Unidade>>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    throw AuthException('Sessão expirada. Entre novamente.');
  }
  return ref.watch(operadorRepositoryProvider).listarUnidades(userId);
});

class UnidadeSelecionadaNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selecionar(String id) => state = id;
}

final unidadeSelecionadaProvider =
    NotifierProvider<UnidadeSelecionadaNotifier, String?>(
  UnidadeSelecionadaNotifier.new,
);

/// Unidade escolhida no drawer; por padrão, a primeira do operador.
final unidadeAtivaIdProvider = Provider<String?>((ref) {
  final selecionada = ref.watch(unidadeSelecionadaProvider);
  if (selecionada != null) return selecionada;
  final lista = ref.watch(unidadesProvider).value;
  if (lista == null || lista.isEmpty) return null;
  return lista.first.id;
});

final catalogoProvider = FutureProvider<Catalogo>((ref) async {
  final unidadeId = ref.watch(unidadeAtivaIdProvider);
  if (unidadeId == null) {
    return const Catalogo(alunos: [], produtos: []);
  }
  return ref.watch(operadorRepositoryProvider).carregarCatalogo(unidadeId);
});

final historicoVendasProvider = FutureProvider<List<VendaResumo>>((ref) async {
  final unidadeId = ref.watch(unidadeAtivaIdProvider);
  if (unidadeId == null) return const [];
  return ref.watch(operadorRepositoryProvider).listarVendas(unidadeId);
});

class OperadorRepository {
  OperadorRepository(this._db);

  final SupabaseClient _db;

  Future<List<Unidade>> listarUnidades(String userId) async {
    final vinculos = await _db
        .from('membro_unidade')
        .select('id_unid')
        .eq('id_usuario', userId)
        .eq('ativo', true);
    final ids = vinculos.map((v) => v['id_unid'] as String).toSet().toList();
    if (ids.isEmpty) return [];
    final rows = await _db
        .from('unidade')
        .select('id_unidade, nome')
        .inFilter('id_unidade', ids)
        .order('nome');
    return rows
        .map((r) => Unidade(
              id: r['id_unidade'] as String,
              nome: _texto(r['nome']) ?? 'Unidade',
            ))
        .toList();
  }

  Future<Catalogo> carregarCatalogo(String unidadeId) async {
    final links = await _db
        .from('aluno_unidade')
        .select('id_aluno')
        .eq('id_unid', unidadeId)
        .eq('ativo', true);
    final ids = links.map((l) => l['id_aluno'] as String).toSet().toList();

    final alunosRows = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('aluno')
            .select('id_aluno, nome_completo_aluno, serie')
            .inFilter('id_aluno', ids)
            .eq('ativo', true);
    final carteirasRows = ids.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('carteira')
            .select('id_carteira, id_aluno, saldo')
            .inFilter('id_aluno', ids)
            .eq('id_unid', unidadeId);

    final carteiraPorAluno = <String, Map<String, dynamic>>{};
    for (final c in carteirasRows) {
      carteiraPorAluno.putIfAbsent(c['id_aluno'] as String, () => c);
    }

    final alunos = alunosRows.map((a) {
      final id = a['id_aluno'] as String;
      final carteira = carteiraPorAluno[id];
      return AlunoVenda(
        idAluno: id,
        nome: _texto(a['nome_completo_aluno']) ?? 'Aluno',
        serie: _texto(a['serie']) ?? '',
        carteiraId: carteira?['id_carteira'] as String?,
        saldo: _numero(carteira?['saldo']),
      );
    }).toList()
      ..sort((x, y) => x.nome.compareTo(y.nome));

    final prodRows = await _db
        .from('produto')
        .select('id, nome, preco')
        .eq('id_unidade', unidadeId)
        .eq('ativo', true)
        .order('nome');
    final estoqueRows = await _db
        .from('estoque')
        .select('id_produto, quantidade')
        .eq('id_unidade', unidadeId);
    final estoque = {
      for (final e in estoqueRows)
        e['id_produto'] as String: _numero(e['quantidade']),
    };

    final produtos = prodRows.map((p) {
      final id = p['id'] as String;
      return ProdutoVenda(
        id: id,
        nome: _texto(p['nome']) ?? 'Produto',
        preco: _numero(p['preco']),
        estoque: estoque[id] ?? 0,
      );
    }).toList();

    return Catalogo(alunos: alunos, produtos: produtos);
  }

  Future<List<VendaResumo>> listarVendas(String unidadeId) async {
    final vendas = await _db
        .from('venda')
        .select('id_venda, id_aluno, status, total, criado_em')
        .eq('id_unid', unidadeId)
        .order('criado_em', ascending: false)
        .limit(100);
    if (vendas.isEmpty) return [];

    final vendaIds = vendas.map((v) => v['id_venda'] as String).toList();
    final alunoIds = vendas
        .map((v) => v['id_aluno'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final alunoRows = alunoIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('aluno')
            .select('id_aluno, nome_completo_aluno')
            .inFilter('id_aluno', alunoIds);
    final alunoNome = {
      for (final a in alunoRows)
        a['id_aluno'] as String: _texto(a['nome_completo_aluno']) ?? 'Aluno',
    };

    final itemRows = await _db
        .from('itens_venda')
        .select('id_venda, id_produto, quantidade, preco_unitario, total_itens')
        .inFilter('id_venda', vendaIds);
    final prodIds =
        itemRows.map((i) => i['id_produto'] as String).toSet().toList();
    final prodRows = prodIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('produto')
            .select('id, nome')
            .inFilter('id', prodIds);
    final prodNome = {
      for (final p in prodRows) p['id'] as String: _texto(p['nome']) ?? 'Produto',
    };

    final itensPorVenda = <String, List<ItemVendaHistorico>>{};
    for (final i in itemRows) {
      (itensPorVenda[i['id_venda'] as String] ??= []).add(
        ItemVendaHistorico(
          produto: prodNome[i['id_produto'] as String] ?? 'Produto',
          quantidade: _numero(i['quantidade']),
          precoUnitario: _numero(i['preco_unitario']),
          total: _numero(i['total_itens']),
        ),
      );
    }

    return vendas.map((v) {
      final id = v['id_venda'] as String;
      final alunoId = v['id_aluno'] as String?;
      return VendaResumo(
        id: id,
        criadoEm: _data(v['criado_em']),
        status: v['status'] as String? ?? 'pending',
        total: _numero(v['total']),
        alunoNome: alunoId == null ? null : alunoNome[alunoId],
        itens: itensPorVenda[id] ?? const [],
      );
    }).toList();
  }

  /// Registra a venda. O pagamento é sempre 'carteira' (débito no saldo do aluno).
  Future<String> registrarVenda({
    required String unidadeId,
    required String idAluno,
    required List<ItemCarrinho> itens,
  }) async {
    final resultado = await _db.rpc(
      'registrar_venda',
      params: {
        'p_id_unid': unidadeId,
        'p_id_aluno': idAluno,
        'p_metodo_pagamento': 'carteira',
        'p_itens': [
          for (final i in itens)
            {
              'id_produto': i.produto.id,
              'quantidade': i.quantidade.toDouble(),
              'preco_unitario': i.produto.preco,
            },
        ],
      },
    );
    return resultado.toString();
  }

  Future<void> estornarVenda(String idVenda) async {
    await _db.rpc('estornar_venda', params: {'p_id_venda': idVenda});
  }

  /// Lança crédito na carteira do aluno (recarga). Retorna o novo saldo.
  Future<double> recarregarCarteira({
    required String carteiraId,
    required double valor,
  }) async {
    final resultado = await _db.rpc(
      'recarregar_carteira',
      params: {'p_id_carteira': carteiraId, 'p_valor': valor},
    );
    return _numero(resultado);
  }

  Future<void> ajustarEstoque({
    required String unidadeId,
    required String produtoId,
    required double quantidade,
  }) async {
    await _db
        .from('estoque')
        .update({
          'quantidade': quantidade,
          'atualizado_em': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id_unidade', unidadeId)
        .eq('id_produto', produtoId);
  }

  static String? _texto(dynamic valor) {
    final s = valor?.toString().trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  static double _numero(dynamic valor) {
    if (valor is num) return valor.toDouble();
    return double.tryParse(valor?.toString() ?? '') ?? 0;
  }

  static DateTime _data(dynamic valor) =>
      DateTime.tryParse(valor?.toString() ?? '')?.toLocal() ?? DateTime.now();
}
