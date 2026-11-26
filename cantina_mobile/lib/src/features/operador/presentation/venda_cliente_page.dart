import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/operador_repository.dart';
import '../domain/operador_models.dart';
import 'operador_state.dart';
import 'widgets/operador_widgets.dart';

class VendaClientePage extends ConsumerStatefulWidget {
  const VendaClientePage({super.key});

  @override
  ConsumerState<VendaClientePage> createState() => _VendaClientePageState();
}

class _VendaClientePageState extends ConsumerState<VendaClientePage> {
  final _buscaAluno = TextEditingController();
  final _buscaProduto = TextEditingController();

  @override
  void dispose() {
    _buscaAluno.dispose();
    _buscaProduto.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogo = ref.watch(catalogoProvider);
    final venda = ref.watch(vendaProvider);
    return catalogo.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ErroOperador(
        onTentar: () => ref.invalidate(catalogoProvider),
      ),
      data: (cat) => _conteudo(cat, venda),
    );
  }

  Widget _conteudo(Catalogo cat, VendaState venda) {
    final notifier = ref.read(vendaProvider.notifier);
    final aluno = venda.aluno;
    final termoA = _buscaAluno.text.trim().toLowerCase();
    final termoP = _buscaProduto.text.trim().toLowerCase();

    final alunosEncontrados = (termoA.isEmpty || aluno != null)
        ? const <AlunoVenda>[]
        : cat.alunos
            .where((a) => a.nome.toLowerCase().contains(termoA))
            .take(5)
            .toList();
    final produtos = cat.produtos
        .where((p) => termoP.isEmpty || p.nome.toLowerCase().contains(termoP))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            children: [
              const TituloEtapa(
                etapa: 'NOVA VENDA • ETAPA 1 DE 3',
                titulo: 'Cliente e produtos',
                subtitulo: 'Busque, selecione e informe a quantidade.',
              ),
              const SizedBox(height: 20),
              CardOp(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cliente',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    if (aluno == null) ...[
                      CampoBusca(
                        controller: _buscaAluno,
                        hint: 'Buscar por nome ou matrícula',
                        onChanged: (_) => setState(() {}),
                      ),
                      for (final a in alunosEncontrados)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(a.nome,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text(a.serie),
                          onTap: () {
                            notifier.selecionarAluno(a);
                            _buscaAluno.clear();
                            setState(() {});
                          },
                        ),
                      const SizedBox(height: 4),
                      const Text(
                        'Selecione o aluno para liberar o pedido. O pagamento é feito pelo saldo da carteira.',
                        style: TextStyle(fontSize: 12, color: CantinaColors.cinza),
                      ),
                    ] else
                      _AlunoSelecionado(
                        aluno: aluno,
                        onLimpar: () {
                          notifier.limparAluno();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Produtos',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 8),
              CampoBusca(
                controller: _buscaProduto,
                hint: 'Nome ou código do produto',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              for (final p in produtos)
                _ProdutoTile(produto: p, venda: venda, notifier: notifier),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: CantinaColors.branco,
            boxShadow: [
              BoxShadow(color: Color(0x14000000), blurRadius: 10, offset: Offset(0, -2)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text('${venda.itens.length} itens selecionados'),
                    const Spacer(),
                    Text(
                      formatReais(venda.total),
                      style: const TextStyle(
                        color: CantinaColors.vinho,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BotaoPrimario(
                  label: 'Conferir pedido →',
                  onPressed: !venda.podeConferir
                      ? null
                      : () => ref.read(operadorTabProvider.notifier).irPara(1),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _AlunoSelecionado extends StatelessWidget {
  const _AlunoSelecionado({required this.aluno, required this.onLimpar});

  final AlunoVenda aluno;
  final VoidCallback onLimpar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CantinaColors.bege,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CantinaColors.vinho),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(aluno.nome,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                Text(aluno.serie,
                    style: const TextStyle(fontSize: 12, color: CantinaColors.cinza)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Saldo',
                  style: TextStyle(fontSize: 11, color: CantinaColors.cinza)),
              Text(
                formatReais(aluno.saldo),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: CantinaColors.vinho,
                ),
              ),
            ],
          ),
          IconButton(
            tooltip: 'Remover cliente',
            icon: const Icon(Icons.close, color: CantinaColors.vinho),
            onPressed: onLimpar,
          ),
        ],
      ),
    );
  }
}

class _ProdutoTile extends StatelessWidget {
  const _ProdutoTile({
    required this.produto,
    required this.venda,
    required this.notifier,
  });

  final ProdutoVenda produto;
  final VendaState venda;
  final VendaNotifier notifier;

  @override
  Widget build(BuildContext context) {
    final qtd = venda.quantidadeDe(produto.id);
    final semEstoque = produto.estoque <= 0;
    final selecionado = qtd > 0;
    final maximo = produto.estoque.floor();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardOp(
        borda: selecionado ? CantinaColors.vinho : null,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(produto.nome,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(
                    '${formatReais(produto.preco)} • Estoque: '
                    '${formatQuantidadeCurta(produto.estoque)}',
                    style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
                  ),
                ],
              ),
            ),
            if (!selecionado)
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: CantinaColors.vinho,
                  side: const BorderSide(color: CantinaColors.vinho),
                ),
                onPressed: semEstoque ? null : () => notifier.ajustar(produto, 1),
                child: const Text('Selecionar'),
              )
            else
              SeletorQuantidade(
                valor: qtd,
                onMenos: () => notifier.ajustar(produto, -1),
                onMais: qtd >= maximo ? null : () => notifier.ajustar(produto, 1),
              ),
          ],
        ),
      ),
    );
  }
}
