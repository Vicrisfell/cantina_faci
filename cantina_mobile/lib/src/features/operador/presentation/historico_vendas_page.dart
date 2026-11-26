import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/cantina_colors.dart';
import '../../../core/utils/formatters.dart';
import '../data/operador_repository.dart';
import '../domain/operador_models.dart';
import 'operador_state.dart';
import 'widgets/operador_widgets.dart';

class HistoricoVendasPage extends ConsumerStatefulWidget {
  const HistoricoVendasPage({super.key});

  @override
  ConsumerState<HistoricoVendasPage> createState() =>
      _HistoricoVendasPageState();
}

class _HistoricoVendasPageState extends ConsumerState<HistoricoVendasPage> {
  final _busca = TextEditingController();

  @override
  void dispose() {
    _busca.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historico = ref.watch(historicoVendasProvider);
    return historico.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => ErroOperador(
        onTentar: () => ref.invalidate(historicoVendasProvider),
      ),
      data: _conteudo,
    );
  }

  Widget _conteudo(List<VendaResumo> vendas) {
    final termo = _busca.text.trim().toLowerCase();
    final filtradas = vendas.where((v) {
      if (termo.isEmpty) return true;
      return (v.alunoNome ?? 'aluno não identificado').toLowerCase().contains(termo) ||
          v.id.toLowerCase().startsWith(termo);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        const TituloEtapa(
          titulo: 'Histórico de vendas',
          subtitulo: 'Todas as vendas registradas no sistema.',
        ),
        const SizedBox(height: 20),
        CardOp(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Vendas registradas',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: CantinaColors.bege,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '${vendas.length} vendas',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: CantinaColors.vinho,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CampoBusca(
                controller: _busca,
                hint: 'Nome do aluno ou nº da venda',
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              if (vendas.isEmpty)
                _EstadoVazio()
              else if (filtradas.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text('Nenhuma venda encontrada com esses filtros.',
                        style: TextStyle(color: CantinaColors.cinza)),
                  ),
                )
              else
                for (final v in filtradas) _VendaTile(venda: v),
            ],
          ),
        ),
      ],
    );
  }
}

class _EstadoVazio extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: CantinaColors.bege,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                color: CantinaColors.vinho, size: 30),
          ),
          const SizedBox(height: 14),
          const Text('Nenhuma venda registrada',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'As vendas finalizadas aparecerão aqui com os itens, o pagamento e o valor total.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: CantinaColors.cinza),
          ),
          const SizedBox(height: 16),
          BotaoPrimario(
            label: '+ Registrar nova venda',
            onPressed: () => ref.read(operadorTabProvider.notifier).irPara(0),
          ),
        ],
      ),
    );
  }
}

class _VendaTile extends StatelessWidget {
  const _VendaTile({required this.venda});

  final VendaResumo venda;

  @override
  Widget build(BuildContext context) {
    final curto = venda.id.length > 8 ? venda.id.substring(0, 8) : venda.id;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: CantinaColors.branco,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (_) => _DetalheVenda(venda: venda),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: CantinaColors.creme,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venda.alunoNome ?? 'Aluno não identificado',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatDataHora(venda.criadoEm)} • #$curto',
                      style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: CantinaColors.bege,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Crédito em carteira',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: CantinaColors.vinho,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    formatReais(venda.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: CantinaColors.vinho,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(venda.statusRotulo,
                      style: const TextStyle(fontSize: 11, color: CantinaColors.cinza)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalheVenda extends ConsumerWidget {
  const _DetalheVenda({required this.venda});

  final VendaResumo venda;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final curto = venda.id.length > 8 ? venda.id.substring(0, 8) : venda.id;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Venda #$curto',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: 2),
          Text(
            '${venda.alunoNome ?? 'Aluno não identificado'} • ${formatDataHora(venda.criadoEm)}',
            style: const TextStyle(fontSize: 12, color: CantinaColors.cinza),
          ),
          const Divider(height: 24),
          if (venda.itens.isEmpty)
            const Text('Sem itens registrados.',
                style: TextStyle(color: CantinaColors.cinza)),
          for (final i in venda.itens)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatQuantidadeCurta(i.quantidade)}x ${i.produto}',
                    ),
                  ),
                  Text(formatReais(i.total)),
                ],
              ),
            ),
          const Divider(height: 24),
          linhaResumo('Total', formatReais(venda.total),
              destaque: true, cor: CantinaColors.vinho),
          linhaResumo('Status', venda.statusRotulo),
          const SizedBox(height: 16),
          if (venda.concluida)
            BotaoContorno(
              label: 'Estornar Venda',
              onPressed: () => _estornar(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _estornar(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Estornar venda?'),
        content: const Text(
          'Os itens voltam ao estoque e, se a venda foi no crédito, o saldo é devolvido ao aluno.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: CantinaColors.vinho),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Estornar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref.read(operadorRepositoryProvider).estornarVenda(venda.id);
      ref.invalidate(historicoVendasProvider);
      ref.invalidate(catalogoProvider);
      if (context.mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Venda estornada com sucesso.')));
      }
    } on PostgrestException catch (erro) {
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    } catch (erro) {
      if (context.mounted) mostrarSnack(context, mensagemErroOperador(erro));
    }
  }
}
