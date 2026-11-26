import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/operador_models.dart';

/// Aba ativa: 0 = Cliente e produtos, 1 = Conferir, 2 = Pagamento, 3 = Histórico.
class OperadorTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void irPara(int indice) => state = indice;
}

final operadorTabProvider = NotifierProvider<OperadorTabNotifier, int>(
  OperadorTabNotifier.new,
);

class VendaState {
  const VendaState({this.aluno, this.itens = const {}, this.enviando = false});

  /// Aluno obrigatório: a venda só existe com um aluno selecionado.
  final AlunoVenda? aluno;
  final Map<String, ItemCarrinho> itens;
  final bool enviando;

  List<ItemCarrinho> get lista => itens.values.toList();

  int get unidades => itens.values.fold(0, (soma, i) => soma + i.quantidade);

  double get total => itens.values.fold(0.0, (soma, i) => soma + i.subtotal);

  int quantidadeDe(String produtoId) => itens[produtoId]?.quantidade ?? 0;

  /// Libera a etapa 2: aluno selecionado E ao menos 1 produto no carrinho.
  bool get podeConferir => aluno != null && itens.isNotEmpty;

  VendaState copyWith({
    AlunoVenda? aluno,
    bool limparAluno = false,
    Map<String, ItemCarrinho>? itens,
    bool? enviando,
  }) {
    return VendaState(
      aluno: limparAluno ? null : (aluno ?? this.aluno),
      itens: itens ?? this.itens,
      enviando: enviando ?? this.enviando,
    );
  }
}

class VendaNotifier extends Notifier<VendaState> {
  @override
  VendaState build() => const VendaState();

  void selecionarAluno(AlunoVenda aluno) =>
      state = state.copyWith(aluno: aluno);

  void limparAluno() => state = state.copyWith(limparAluno: true);

  /// Soma [delta] à quantidade do produto, respeitando o estoque disponível.
  void ajustar(ProdutoVenda produto, int delta) {
    final maximo = produto.estoque.floor();
    final nova = max(0, min(maximo, state.quantidadeDe(produto.id) + delta));
    final mapa = Map<String, ItemCarrinho>.of(state.itens);
    if (nova == 0) {
      mapa.remove(produto.id);
    } else {
      mapa[produto.id] = ItemCarrinho(produto: produto, quantidade: nova);
    }
    state = state.copyWith(itens: mapa);
  }

  void setEnviando(bool valor) => state = state.copyWith(enviando: valor);

  void limpar() => state = const VendaState();
}

final vendaProvider = NotifierProvider<VendaNotifier, VendaState>(
  VendaNotifier.new,
);
