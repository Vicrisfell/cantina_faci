const double limiteSaldoBaixo = 10;
const double metaSaldo = 50;

class ResponsavelPerfil {
  const ResponsavelPerfil({
    required this.nome,
    this.email,
    this.cpf,
    this.celular,
    this.nomeAlternativo,
    this.celularAlternativo,
    this.endereco,
    this.numEnd,
    this.bairro,
    this.cep,
    this.cidade,
    this.estado,
    this.complemento,
  });

  final String nome;
  final String? email;
  final String? cpf;
  final String? celular;
  final String? nomeAlternativo;
  final String? celularAlternativo;
  final String? endereco;
  final String? numEnd;
  final String? bairro;
  final String? cep;
  final String? cidade;
  final String? estado;
  final String? complemento;
}

class Filho {
  const Filho({
    required this.id,
    required this.nome,
    required this.serie,
    required this.ativo,
    required this.instituicao,
    required this.saldo,
  });

  final String id;
  final String nome;
  final String serie;
  final bool ativo;
  final String instituicao;
  final double saldo;

  bool get saldoBaixo => saldo <= limiteSaldoBaixo;
  String get inicial => nome.isEmpty ? '?' : nome[0].toUpperCase();
}

class ItemVenda {
  const ItemVenda({
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

class Venda {
  const Venda({
    required this.id,
    required this.total,
    required this.criadoEm,
    required this.itens,
  });

  final String id;
  final double total;
  final DateTime criadoEm;
  final List<ItemVenda> itens;
}

class Movimento {
  const Movimento({
    required this.id,
    required this.alunoId,
    required this.tipo,
    required this.valor,
    required this.criadoEm,
    this.venda,
  });

  final String id;
  final String alunoId;
  final String tipo;
  final double valor;
  final DateTime criadoEm;
  final Venda? venda;

  bool get isCompra => tipo == 'debito';
}

class ResponsavelData {
  const ResponsavelData({
    required this.perfil,
    required this.filhos,
    required this.movimentos,
    this.vinculoDesde,
  });

  final ResponsavelPerfil perfil;
  final List<Filho> filhos;
  final List<Movimento> movimentos;
  final DateTime? vinculoDesde;

  int get instituicoesCount => filhos.map((f) => f.instituicao).toSet().length;
}
