import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../auth/data/supabase_auth_repository.dart';
import '../domain/responsavel_models.dart';

final responsavelDataProvider = FutureProvider<ResponsavelData>((ref) async {
  final userId = ref.watch(authUserIdProvider).value;
  if (userId == null) {
    throw AuthException('Sessão expirada. Entre novamente.');
  }
  return ResponsavelRepository(Supabase.instance.client).carregar(userId);
});

class ResponsavelRepository {
  ResponsavelRepository(this._db);

  final SupabaseClient _db;

  Future<ResponsavelData> carregar(String userId) async {
    final perfilRow = await _db
        .from('cantina_profiles')
        .select('nome, email, cpf')
        .eq('id', userId)
        .single();
    final contato = (await _db
            .from('membros_organizacao')
            .select(
              'endereco, num_end, bairro, cep, cidade, estado, complemento, '
              'celular, nome_contato_alternativo, celular_contato_alternativo',
            )
            .eq('id_usuario', userId)
            .maybeSingle()) ??
        <String, dynamic>{};

    final perfil = ResponsavelPerfil(
      nome: _texto(perfilRow['nome']) ?? 'Responsável',
      email: _texto(perfilRow['email']),
      cpf: _texto(perfilRow['cpf']),
      celular: _texto(contato['celular']),
      nomeAlternativo: _texto(contato['nome_contato_alternativo']),
      celularAlternativo: _texto(contato['celular_contato_alternativo']),
      endereco: _texto(contato['endereco']),
      numEnd: _texto(contato['num_end']),
      bairro: _texto(contato['bairro']),
      cep: _texto(contato['cep']),
      cidade: _texto(contato['cidade']),
      estado: _texto(contato['estado']),
      complemento: _texto(contato['complemento']),
    );

    final vinculos = await _db
        .from('responsavel_aluno')
        .select('id_aluno, criado_em')
        .eq('id_usuario_responsavel', userId);
    if (vinculos.isEmpty) {
      return ResponsavelData(
        perfil: perfil,
        filhos: const [],
        movimentos: const [],
      );
    }

    DateTime? desde;
    for (final v in vinculos) {
      final d = DateTime.tryParse(v['criado_em']?.toString() ?? '');
      if (d != null && (desde == null || d.isBefore(desde))) desde = d;
    }

    final alunoIds = vinculos.map((v) => v['id_aluno'] as String).toSet().toList();

    final alunosRows = await _db
        .from('aluno')
        .select('id_aluno, nome_completo_aluno, serie, ativo')
        .inFilter('id_aluno', alunoIds);

    final unidadeLinks = await _db
        .from('aluno_unidade')
        .select('id_aluno, id_unid')
        .inFilter('id_aluno', alunoIds)
        .eq('ativo', true);

    final unidadeIds =
        unidadeLinks.map((l) => l['id_unid'] as String).toSet().toList();
    final unidadesRows = unidadeIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('unidade')
            .select('id_unidade, nome')
            .inFilter('id_unidade', unidadeIds);
    final unidadeNomes = {
      for (final u in unidadesRows) u['id_unidade'] as String: u['nome'] as String,
    };

    final carteirasRows = await _db
        .from('carteira')
        .select('id_carteira, id_aluno, saldo')
        .inFilter('id_aluno', alunoIds);
    final carteiraPorAluno = <String, Map<String, dynamic>>{};
    for (final c in carteirasRows) {
      carteiraPorAluno.putIfAbsent(c['id_aluno'] as String, () => c);
    }

    final filhos = <Filho>[];
    for (final aluno in alunosRows) {
      final alunoId = aluno['id_aluno'] as String;
      final vinculo = _primeiro(unidadeLinks, 'id_aluno', alunoId);
      final unidadeId = vinculo?['id_unid'] as String?;
      final carteira = carteiraPorAluno[alunoId];
      filhos.add(
        Filho(
          id: alunoId,
          nome: _texto(aluno['nome_completo_aluno']) ?? 'Aluno',
          serie: _texto(aluno['serie']) ?? 'Série não informada',
          ativo: aluno['ativo'] == true,
          instituicao: unidadeNomes[unidadeId] ?? 'Não informado',
          saldo: _numero(carteira?['saldo']),
        ),
      );
    }

    final carteiraParaAluno = {
      for (final c in carteirasRows)
        c['id_carteira'] as String: c['id_aluno'] as String,
    };
    final carteiraIds = carteiraParaAluno.keys.toList();

    final movRows = carteiraIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('movimentacao_carteira')
            .select('id, id_carteira, id_venda, tipo, valor, criado_em')
            .inFilter('id_carteira', carteiraIds)
            .order('criado_em', ascending: false)
            .limit(200);

    final vendaIds = movRows
        .map((m) => m['id_venda'] as String?)
        .whereType<String>()
        .toSet()
        .toList();

    final vendasRows = vendaIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('venda')
            .select('id_venda, total, criado_em')
            .inFilter('id_venda', vendaIds);
    final itensRows = vendaIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db
            .from('itens_venda')
            .select('id_venda, id_produto, quantidade, preco_unitario, total_itens')
            .inFilter('id_venda', vendaIds);
    final produtoIds =
        itensRows.map((i) => i['id_produto'] as String).toSet().toList();
    final produtosRows = produtoIds.isEmpty
        ? <Map<String, dynamic>>[]
        : await _db.from('produto').select('id, nome').inFilter('id', produtoIds);

    final produtoNome = {
      for (final p in produtosRows)
        p['id'] as String: _texto(p['nome']) ?? 'Produto',
    };
    final itensPorVenda = <String, List<ItemVenda>>{};
    for (final i in itensRows) {
      (itensPorVenda[i['id_venda'] as String] ??= []).add(
        ItemVenda(
          produto: produtoNome[i['id_produto'] as String] ?? 'Produto',
          quantidade: _numero(i['quantidade']),
          precoUnitario: _numero(i['preco_unitario']),
          total: _numero(i['total_itens']),
        ),
      );
    }
    final vendas = <String, Venda>{
      for (final v in vendasRows)
        v['id_venda'] as String: Venda(
          id: v['id_venda'] as String,
          total: _numero(v['total']),
          criadoEm: _data(v['criado_em']),
          itens: itensPorVenda[v['id_venda'] as String] ?? const [],
        ),
    };

    final movimentos = movRows.map((m) {
      final vendaId = m['id_venda'] as String?;
      return Movimento(
        id: m['id'].toString(),
        alunoId: carteiraParaAluno[m['id_carteira'] as String] ?? '',
        tipo: m['tipo'] as String,
        valor: _numero(m['valor']),
        criadoEm: _data(m['criado_em']),
        venda: vendaId == null ? null : vendas[vendaId],
      );
    }).toList();

    return ResponsavelData(
      perfil: perfil,
      filhos: filhos,
      movimentos: movimentos,
      vinculoDesde: desde,
    );
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

  static Map<String, dynamic>? _primeiro(
    List<Map<String, dynamic>> lista,
    String campo,
    String valor,
  ) {
    for (final item in lista) {
      if (item[campo] == valor) return item;
    }
    return null;
  }
}
