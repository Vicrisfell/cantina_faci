import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import 'operador_state.dart';
import 'widgets/operador_widgets.dart';

class VendaConferirPage extends ConsumerWidget {
  const VendaConferirPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venda = ref.watch(vendaProvider);
    final tab = ref.read(operadorTabProvider.notifier);
    final aluno = venda.aluno;
    final total = venda.total;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const TituloEtapa(
          etapa: 'NOVA VENDA • ETAPA 2 DE 3',
          titulo: 'Conferir pedido',
          subtitulo: 'Confira as quantidades e o valor da compra.',
        ),
        const SizedBox(height: 20),
        CardOp(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Cliente',
                        style: TextStyle(fontSize: 11, color: CantinaColors.cinza)),
                    Text(
                      aluno?.nome ?? 'Aluno não selecionado',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                    if (aluno != null)
                      Text(aluno.serie,
                          style: const TextStyle(
                              fontSize: 12, color: CantinaColors.cinza)),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => tab.irPara(0),
                child: const Text('Alterar',
                    style: TextStyle(
                        color: CantinaColors.vinho, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CardOp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Itens do pedido',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              Text(
                '${venda.itens.length} produtos • ${venda.unidades} unidades',
                style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
              ),
              const SizedBox(height: 8),
              for (final item in venda.lista) ...[
                const Divider(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.produto.nome,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${item.quantidade} un. × '
                            '${formatReais(item.produto.preco)}',
                            style: const TextStyle(
                                fontSize: 12, color: CantinaColors.cinza),
                          ),
                          Text('Quantidade: ${item.quantidade}',
                              style: const TextStyle(
                                  fontSize: 12, color: CantinaColors.cinza)),
                        ],
                      ),
                    ),
                    Text(
                      formatReais(item.subtotal),
                      style: const TextStyle(
                        color: CantinaColors.vinho,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        CardOp(
          child: Column(
            children: [
              linhaResumo('Subtotal', formatReais(total)),
              const Divider(height: 20),
              linhaResumo('Total a pagar', formatReais(total),
                  destaque: true, cor: CantinaColors.vinho),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${venda.unidades} unidades no pedido',
                  style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        BotaoContorno(
          label: '+ Adicionar ou editar produtos',
          onPressed: () => tab.irPara(0),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Você pode voltar sem perder os itens.',
            style: TextStyle(fontSize: 12, color: CantinaColors.cinza),
          ),
        ),
        const SizedBox(height: 16),
        BotaoPrimario(
          label: 'Confirmar itens e continuar →',
          onPressed: venda.podeConferir ? () => tab.irPara(2) : null,
        ),
      ],
    );
  }
}
