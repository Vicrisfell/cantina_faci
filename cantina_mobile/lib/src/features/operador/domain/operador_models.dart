import 'package:flutter/material.dart';

enum PerfilAcesso { responsavel, operador }

enum MetodoPagamento {
  /// Única forma de pagamento do sistema: débito no saldo da carteira do aluno.
  carteira('Crédito em Carteira', 'Débito automático no saldo do aluno', Icons.account_balance_wallet_outlined);

  const MetodoPagamento(this.rotulo, this.descricao, this.icone);

  final String rotulo;
  final String descricao;
  final IconData icone;
}

class Unidade {
  const Unidade({required this.id, required this.nome});

  final String id;
  final String nome;
}

class AlunoVenda {
  const AlunoVenda({
    required this.idAluno,
    required this.nome,
    required this.serie,
    required this.carteiraId,
    required this.saldo,
  });

  final String idAluno;
  final String nome;
  final String serie;
  final String? carteiraId;
  final double saldo;
}

class ProdutoVenda {
  const ProdutoVenda({
    required this.id,
    required this.nome,
    required this.preco,
    required this.estoque,
  });

  final String id;
  final String nome;
  final double preco;
  final double estoque;
}

class ItemCarrinho {
  const ItemCarrinho({required this.produto, required this.quantidade});

  final ProdutoVenda produto;
  final int quantidade;

  double get subtotal => produto.preco * quantidade;
}

class ItemVendaHistorico {
  const ItemVendaHistorico({
    required this.produto,
    required this.quantidade,
    required this.precoUnitario,
    required this.total,
  });

  final String produto;
  final double quantidade;
  final double precoUnitario;
  final double total;
}

class VendaResumo {
  const VendaResumo({
    required this.id,
    required this.criadoEm,
    required this.status,
    required this.total,
    required this.alunoNome,
    required this.itens,
  });

  final String id;
  final DateTime criadoEm;
  final String status;
  final double total;
  final String? alunoNome;
  final List<ItemVendaHistorico> itens;

  bool get concluida => status == 'completed';

  String get statusRotulo => switch (status) {
        'completed' => 'Concluída',
        'cancelled' => 'Cancelada',
        _ => 'Pendente',
      };
}

class Catalogo {
  const Catalogo({required this.alunos, required this.produtos});

  final List<AlunoVenda> alunos;
  final List<ProdutoVenda> produtos;
}
