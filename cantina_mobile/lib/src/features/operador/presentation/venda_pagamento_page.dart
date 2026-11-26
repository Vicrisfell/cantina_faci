import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/operador_repository.dart';
import '../domain/operador_models.dart';
import 'operador_state.dart';
import 'widgets/operador_widgets.dart';

const _vermelhoErro = Color(0xFFB3261E);

class VendaPagamentoPage extends ConsumerWidget {
  const VendaPagamentoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final venda = ref.watch(vendaProvider);
    final unidadeId = ref.watch(unidadeAtivaIdProvider);
    final aluno = venda.aluno;
    final total = venda.total;

    final saldoAtual = aluno?.saldo ?? 0.0;
    final saldoApos = saldoAtual - total;
    final saldoInsuficiente = aluno != null && saldoApos < 0;
    final podeFinalizar = aluno != null &&
        venda.itens.isNotEmpty &&
        !saldoInsuficiente &&
        !venda.enviando &&
        unidadeId != null;

    final nomes = venda.lista.map((i) => i.produto.nome).join(', ');

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const TituloEtapa(
          etapa: 'NOVA VENDA • ETAPA 3 DE 3',
          titulo: 'Pagamento',
          subtitulo: 'Confira o débito no saldo do aluno antes de finalizar.',
        ),
        const SizedBox(height: 20),
        CardOp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(aluno?.nome ?? 'Aluno não selecionado',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              const SizedBox(height: 2),
              Text(
                '${venda.unidades} itens • $nomes',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
              ),
              const Divider(height: 20),
              linhaResumo('Total a pagar', formatReais(total),
                  destaque: true, cor: CantinaColors.vinho),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Forma de pagamento',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 12),
        const _CardCreditoCarteira(),
        const SizedBox(height: 12),
        CardOp(
          borda: saldoInsuficiente ? _vermelhoErro : null,
          child: Column(
            children: [
              linhaResumo('Saldo atual', formatReais(saldoAtual)),
              linhaResumo('Valor da compra', '- ${formatReais(total)}'),
              const Divider(height: 16),
              linhaResumo(
                'Saldo após a venda',
                formatReais(saldoApos),
                destaque: true,
                cor: saldoInsuficiente ? _vermelhoErro : CantinaColors.vinho,
              ),
            ],
          ),
        ),
        if (saldoInsuficiente) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9E3E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _vermelhoErro),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: _vermelhoErro),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Saldo da carteira insuficiente para concluir esta compra.',
                    style: TextStyle(color: _vermelhoErro, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        BotaoPrimario(
          label: venda.enviando
              ? 'Registrando venda...'
              : 'Finalizar venda • ${formatReais(total)}',
          onPressed: podeFinalizar
              ? () => _finalizar(context, ref, venda, unidadeId)
              : null,
        ),
      ],
    );
  }

  Future<void> _finalizar(
    BuildContext context,
    WidgetRef ref,
    VendaState venda,
    String unidadeId,
  ) async {
    final aluno = venda.aluno;
    if (aluno == null) return;
    final notifier = ref.read(vendaProvider.notifier);
    notifier.setEnviando(true);
    try {
      final idVenda = await ref.read(operadorRepositoryProvider).registrarVenda(
            unidadeId: unidadeId,
            idAluno: aluno.idAluno,
            itens: venda.lista,
          );
      notifier.limpar();
      ref.invalidate(catalogoProvider);
      ref.invalidate(historicoVendasProvider);
      if (!context.mounted) return;
      ref.read(operadorTabProvider.notifier).irPara(0);
      final curto = idVenda.length > 8 ? idVenda.substring(0, 8) : idVenda;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: CantinaColors.vinho, size: 40),
          title: const Text('Venda registrada'),
          content: Text(
            'Venda nº $curto concluída. O saldo da carteira e o estoque já foram atualizados.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: CantinaColors.vinho),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Nova venda'),
            ),
          ],
        ),
      );
    } on PostgrestException catch (erro) {
      notifier.setEnviando(false);
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    } catch (erro) {
      notifier.setEnviando(false);
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    }
  }
}

/// Card fixo e selecionado: a única forma de pagamento do sistema.
class _CardCreditoCarteira extends StatelessWidget {
  const _CardCreditoCarteira();

  @override
  Widget build(BuildContext context) {
    final m = MetodoPagamento.carteira;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CantinaColors.vinho,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CantinaColors.vinho),
      ),
      child: Row(
        children: [
          Icon(m.icone, color: Colors.white),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  m.rotulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  m.descricao,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
          const Icon(Icons.check_circle, color: Colors.white),
        ],
      ),
    );
  }
}
