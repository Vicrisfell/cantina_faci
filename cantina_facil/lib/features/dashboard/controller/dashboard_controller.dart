import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/dashboard_repository.dart';
import '../models/dashboard_models.dart';

class DashboardController extends ChangeNotifier {
  DashboardController({
    required this.repo,
    required this.idOrg,
    required this.idsGerenciados,
  });

  final DashboardRepository repo;
  final String? idOrg;
  final List<String> idsGerenciados;

  String nomeOrganizacao = '';
  List<UnidadeOpcao> unidades = const [];
  String? unidadeSelecionada; // null = todas as unidades
  PeriodoDashboard periodo = PeriodoDashboard.esteMes;

  DashboardData? dados;
  bool carregandoInicial = true;
  bool atualizando = false;
  Object? erro;

  RealtimeChannel? _canal;
  Timer? _debounce;
  int _requisicao = 0; // descarta respostas antigas em trocas rápidas de filtro
  bool _descartado = false;

  Future<void> iniciar() async {
    try {
      nomeOrganizacao = idOrg != null
          ? await repo.nomeOrganizacao(idOrg!)
          : 'Unidades gerenciadas';
      unidades = await repo.listarUnidades(idOrg: idOrg, idsPermitidos: idsGerenciados);

      _canal = repo.assinarMudancas(_agendarRecarga);
      await _carregarDados();
    } catch (e) {
      erro = e;
      carregandoInicial = false;
      _notificar();
    }
  }

  void selecionarUnidade(String? id) {
    if (id == unidadeSelecionada) return;
    unidadeSelecionada = id;
    _carregarDados();
  }

  void selecionarPeriodo(PeriodoDashboard p) {
    if (p == periodo) return;
    periodo = p;
    _carregarDados();
  }

  Future<void> recarregar() => _carregarDados();

  Future<void> estornarVenda(String idVenda) async {
    await repo.estornarVenda(idVenda);
    await _carregarDados();
  }

  Future<void> definirEstoque(EstoqueItem item, int novaQuantidade) async {
    await repo.definirEstoque(
      idUnidade: item.idUnidade,
      idProduto: item.idProduto,
      quantidade: novaQuantidade,
    );
    await _carregarDados();
  }

  Future<void> _carregarDados() async {
    final id = ++_requisicao;
    atualizando = true;
    _notificar();

    final ids = unidadeSelecionada == null
        ? unidades.map((u) => u.id).toList()
        : [unidadeSelecionada!];

    try {
      final novo = await repo.carregar(
        idsUnidades: ids,
        inicio: periodo.inicio(DateTime.now()),
      );
      if (id != _requisicao) return;
      dados = novo;
      erro = null;
    } catch (e) {
      if (id != _requisicao) return;
      erro = e;
    } finally {
      if (id == _requisicao) {
        atualizando = false;
        carregandoInicial = false;
        _notificar();
      }
    }
  }

  /// Evita uma recarga por evento quando há rajadas (venda + itens + pagamentos).
  void _agendarRecarga() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _carregarDados);
  }

  void _notificar() {
    if (!_descartado) notifyListeners();
  }

  @override
  void dispose() {
    _descartado = true;
    _debounce?.cancel();
    final canal = _canal;
    if (canal != null) repo.cancelarAssinatura(canal);
    super.dispose();
  }
}
